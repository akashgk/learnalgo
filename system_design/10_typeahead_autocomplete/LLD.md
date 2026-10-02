# Typeahead / Autocomplete: Low-Level Design

## 1. Scope for the LLD round

- `record(query)` counts executed searches; `suggest(prefix)` returns the top k queries starting with the prefix.
- Ranking: higher count first; ties broken alphabetically (deterministic output).
- Queries are **normalized** (lowercase, trimmed, single spaces). Prefixes keep a trailing space, so `new ` does not match `news`.
- **Top k precomputed in every trie node**, so `suggest` is O(prefix length + k).
- `remove(query)` (for example, a newly blocked query) recomputes only the affected path.
- A `Suggester` that **blends trending queries** from a recent time window with the global trie and applies a **blocklist** at serve time.

Out of scope: distributed snapshot building, sharding, client debouncing (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `normalize` | One canonical form per query. |
| `TrieNode` | Children by character, the count of the query ending here, and the top-k list for this prefix. |
| `AutocompleteTrie` | `record`, `remove`, `suggest`; keeps every node's top-k list correct. |
| `TrendingTracker` | Counts queries inside a sliding time window (minute buckets). |
| `Suggester` | Facade for serving: trending first, then global; dedupe; blocklist; k results. |

```text
Suggester --uses--> AutocompleteTrie --has--> TrieNode (children, count, top[k])
          --uses--> TrendingTracker  (minute buckets, sliding window)
          --uses--> blocklist (Set<String>)
```

## 3. Design decisions and why

- **Top k stored per node.** Reads are the hot path (hundreds of thousands per second); writes are rarer and can afford to touch every node on the query's path.
- **Incremental update is valid because counts only increase.** When a query's count rises, it can only move up in, or enter, the top-k list of each node on its path; no other query's position changes relative to the rest. So updating each node's list in O(k log k) is enough.
- **Decreases need recomputation.** When a query is removed, a node's top-k may need an entry that was below the cut-off. Each node on the path is rebuilt bottom-up from its own count and its children's top-k lists, which is exactly how the offline builder in the HLD works.
- **Counts in one map** (`query -> count`), and nodes store only query strings; sorting reads the map. No duplicated counters to keep in sync.
- **Blocklist at serve time** as well as in the trie: a blocked term disappears immediately, without waiting for a rebuild.
- **Trending in a separate structure** merged at query time, as in production: the big trie changes slowly, the trending list changes every minute.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

String normalize(String q) => normalizePrefix(q).trimRight();

/// Like [normalize] but keeps one trailing space: "new " must not match "news".
String normalizePrefix(String p) => p.trimLeft().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class TrieNode {
  final children = <String, TrieNode>{};
  var count = 0; // times the query ending exactly here was searched
  List<String> top = const [];
}

class AutocompleteTrie {
  AutocompleteTrie({this.k = 5});

  final int k;
  final root = TrieNode();
  final _counts = <String, int>{};

  int countOf(String query) => _counts[normalize(query)] ?? 0;

  /// Higher count first, then alphabetical.
  int _rank(String a, String b) {
    final byCount = _counts[b]!.compareTo(_counts[a]!);
    return byCount != 0 ? byCount : a.compareTo(b);
  }

  List<TrieNode> _path(String q, {required bool create}) {
    final path = [root];
    var node = root;
    for (final ch in q.split('')) {
      final next = create ? node.children.putIfAbsent(ch, TrieNode.new) : node.children[ch];
      if (next == null) return const [];
      path.add(node = next);
    }
    return path;
  }

  void record(String query, {int times = 1}) {
    final q = normalize(query);
    if (q.isEmpty || times <= 0) return;
    _counts[q] = (_counts[q] ?? 0) + times;
    final path = _path(q, create: true);
    path.last.count = _counts[q]!;
    for (final node in path) {
      // Counts only grew, so a local update of each list on the path is enough.
      final list = [...node.top.where((s) => s != q), q]..sort(_rank);
      node.top = list.length > k ? list.sublist(0, k) : list;
    }
  }

  bool remove(String query) {
    final q = normalize(query);
    final path = _path(q, create: false);
    if (path.isEmpty || path.last.count == 0) return false;
    _counts.remove(q);
    path.last.count = 0;
    // Rebuild bottom-up: a node's top k comes from its own query and its children's top k.
    var prefix = q;
    for (final node in path.reversed) {
      final candidates = <String>{
        if (node.count > 0) prefix,
        for (final child in node.children.values) ...child.top,
      }.toList()..sort(_rank);
      node.top = candidates.length > k ? candidates.sublist(0, k) : candidates;
      if (prefix.isNotEmpty) prefix = prefix.substring(0, prefix.length - 1);
    }
    return true;
  }

  List<String> suggest(String prefix) {
    final p = normalizePrefix(prefix);
    if (p.isEmpty) return const [];
    final path = _path(p, create: false);
    return path.isEmpty ? const [] : path.last.top;
  }
}

// ---------- Trending and serving ----------

class TrendingTracker {
  TrendingTracker({required this.windowMinutes});
  final int windowMinutes;
  final _buckets = Queue<(int, Map<String, int>)>(); // (minute, counts), oldest first

  void record(String query, int minute) {
    final q = normalize(query);
    if (_buckets.isNotEmpty && minute < _buckets.last.$1) throw ArgumentError('minutes must not go backwards');
    if (_buckets.isEmpty || _buckets.last.$1 != minute) _buckets.add((minute, <String, int>{}));
    final counts = _buckets.last.$2;
    counts[q] = (counts[q] ?? 0) + 1;
  }

  /// Queries with at least [minCount] searches in the window ending at [nowMinute], best first.
  List<String> top(String prefix, int nowMinute, {required int minCount}) {
    while (_buckets.isNotEmpty && _buckets.first.$1 <= nowMinute - windowMinutes) {
      _buckets.removeFirst();
    }
    final p = normalizePrefix(prefix);
    final totals = <String, int>{};
    for (final (_, counts) in _buckets) {
      counts.forEach((q, c) {
        if (q.startsWith(p)) totals[q] = (totals[q] ?? 0) + c;
      });
    }
    final hot = totals.keys.where((q) => totals[q]! >= minCount).toList()
      ..sort((a, b) => totals[b] != totals[a] ? totals[b]!.compareTo(totals[a]!) : a.compareTo(b));
    return hot;
  }
}

class Suggester {
  Suggester(this.trie, this.trending, {this.k = 5, this.maxTrending = 2, this.minTrendingCount = 3});

  final AutocompleteTrie trie;
  final TrendingTracker trending;
  final int k;
  final int maxTrending;
  final int minTrendingCount;
  final blocklist = <String>{};

  void block(String query) {
    blocklist.add(normalize(query));
    trie.remove(query);
  }

  List<String> suggest(String prefix, int nowMinute) {
    bool allowed(String q) => !blocklist.any(q.contains);
    final out = <String>{};
    out.addAll(trending.top(prefix, nowMinute, minCount: minTrendingCount).where(allowed).take(maxTrending));
    for (final q in trie.suggest(prefix).where(allowed)) {
      if (out.length == k) break;
      out.add(q);
    }
    return out.take(k).toList();
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

List<String> bruteForce(Map<String, int> counts, String prefix, int k) {
  final matches = counts.keys.where((q) => q.startsWith(prefix)).toList()
    ..sort((a, b) => counts[b] != counts[a] ? counts[b]!.compareTo(counts[a]!) : a.compareTo(b));
  return matches.take(k).toList();
}

void main() {
  check(normalize('  New   York '), 'new york');
  check(normalizePrefix('NEW '), 'new ');

  final trie = AutocompleteTrie(k: 3);
  for (final (q, n) in [
    ('new york', 5),
    ('new york times', 3),
    ('netflix', 4),
    ('news', 2),
    ('nike', 1),
    ('new jersey', 2),
  ]) {
    trie.record(q, times: n);
  }
  check(trie.suggest('ne'), ['new york', 'netflix', 'new york times']);
  check(trie.suggest('NEW '), ['new york', 'new york times', 'new jersey']);
  check(trie.suggest('n'), ['new york', 'netflix', 'new york times']);
  check(trie.suggest('x'), []);

  // A query climbing into the top 3; ties broken alphabetically ('new york' < 'news').
  trie.record('news', times: 3);
  check(trie.suggest('ne'), ['new york', 'news', 'netflix']);

  // Removal recomputes the path: 'new york times' (3) re-enters for 'ne' from below the cut-off.
  check(trie.remove('new york'), true);
  check(trie.suggest('ne'), ['news', 'netflix', 'new york times']);
  check(trie.suggest('new y'), ['new york times']);
  check(trie.remove('new york'), false);

  // Randomized comparison with brute force over every prefix up to length 3.
  final rng = Random(7);
  final fuzz = AutocompleteTrie(k: 4);
  final counts = <String, int>{};
  for (var i = 0; i < 3000; i++) {
    final q = String.fromCharCodes(List.generate(1 + rng.nextInt(5), (_) => 97 + rng.nextInt(3)));
    fuzz.record(q);
    counts[q] = (counts[q] ?? 0) + 1;
    if (i % 500 == 499) {
      // Occasional removals exercise the recompute path.
      final victim = counts.keys.elementAt(rng.nextInt(counts.length));
      fuzz.remove(victim);
      counts.remove(victim);
    }
  }
  var prefixesChecked = 0;
  for (final a in ['a', 'b', 'c']) {
    for (final b in ['', 'a', 'b', 'c']) {
      for (final c in ['', 'a', 'b', 'c']) {
        if (b.isEmpty && c.isNotEmpty) continue;
        final p = '$a$b$c';
        if ('${fuzz.suggest(p)}' != '${bruteForce(counts, p, 4)}') throw StateError('mismatch at $p');
        prefixesChecked++;
      }
    }
  }
  check(prefixesChecked, 39);

  // Serving: trending first, blocklist applied, trending expires with the window.
  final global = AutocompleteTrie(k: 4)
    ..record('netflix', times: 100)
    ..record('news', times: 90)
    ..record('nike', times: 80)
    ..record('new york', times: 70)
    ..record('nepal', times: 10);
  final trending = TrendingTracker(windowMinutes: 60);
  final suggester = Suggester(global, trending, k: 4);
  for (var i = 0; i < 5; i++) {
    trending.record('nepal earthquake', 1000 + i);
  }
  trending.record('new phone', 1004); // below the trending threshold
  check(suggester.suggest('ne', 1010), ['nepal earthquake', 'netflix', 'news', 'new york']);
  suggester.block('netflix');
  check(suggester.suggest('ne', 1010), ['nepal earthquake', 'news', 'new york', 'nepal']);
  check(suggester.suggest('ne', 1065), ['news', 'new york', 'nepal']); // window passed
  check(suggester.suggest('n', 1065), ['news', 'nike', 'new york', 'nepal']);
}
```

## 5. Walkthrough

- The node for `ne` holds `[new york (5), netflix (4), new york times (3)]`. `suggest('ne')` returns that list without touching the subtree.
- `record('news', times: 3)` raises `news` to 5. It ties with `new york`, and alphabetical order (`' '` sorts before `'s'`) puts `new york` first.
- Removing `new york` rebuilds the nodes on its path from their children's lists, so `new york times`, which was outside the top 3 at `ne`, comes back in.
- The randomized test builds 3,000 records with periodic removals and checks the trie against a brute-force scan for all 39 prefixes of length 1 to 3.
- In the serving test, `nepal earthquake` has 5 searches in the last hour and is shown first. After `block('netflix')`, it disappears at once, and `nepal` (rank 5 globally) moves into view because `remove` recomputed the trie's top lists. At minute 1065 the burst has left the 60-minute window.

## 6. Concurrency

- Serving reads must not block on updates. Production approach: the trie is **immutable** once built; a new snapshot is built in the background and the reference is swapped atomically (readers see the old or the new trie, never a half-updated one).
- If live incremental updates are needed, a single writer thread applies batched counts while readers use copy-on-write top lists (replace the list reference; never mutate a list readers can see). The code above already assigns a new list rather than mutating `top`.
- `TrendingTracker` is updated by a stream processor; serving nodes receive its output periodically rather than sharing its state.

## 7. Extensibility

| Change | Where |
|---|---|
| Time decay | Store decayed scores instead of counts; the offline builder applies decay before building. |
| Personalization | Another source in `Suggester` (the user's recent queries), merged like trending. |
| Typo tolerance | A bounded edit-distance walk of the trie as a fallback when `suggest` returns too few results. |
| Memory reduction | Compressed trie (radix tree), or store top lists only at depths 1-N and compute deeper ones. |
| Sharding | Route by prefix range; each shard holds a trie of its range. |

## 8. Common mistakes in LLD rounds

- Collecting the whole subtree and sorting on every keystroke.
- Updating top-k lists incrementally on a count **decrease** (gives wrong answers; must recompute).
- Ignoring normalization, so `New York` and `new york` are counted separately.
- Non-deterministic ordering for ties.
- Mutating shared lists that concurrent readers are iterating.

See [HLD.md](HLD.md) for the data pipeline, caching and sharding.
