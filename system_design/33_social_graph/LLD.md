# Social Graph: Low-Level Design

## 1. Scope for the LLD round

- Undirected **connections** stored as adjacency sets in both directions; connect, disconnect, **block** (removes the edge and prevents reconnecting).
- **Degree of connection** up to 3 using **bidirectional BFS** (expand the smaller frontier each step), with the actual path.
- **Mutual connections** (sorted intersection).
- **People You May Know**: friends of friends ranked by mutual count, excluding existing connections, yourself and blocked users.
- A count of adjacency-list fetches, to compare bidirectional and one-sided BFS on a random graph.

Out of scope: connection requests/acceptance flow, storage sharding, offline PYMK pipelines (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `SocialGraph` | Adjacency sets, block lists, fetch counter; all queries. |
| `shortestPath` | Bidirectional BFS with parent maps on both sides; deterministic meeting point. |
| `oneSidedDistance` | Plain BFS used as the baseline in tests. |

```text
SocialGraph: _adj: user -> Set<friend> (both directions)     _blocked: user -> Set<user>
   degree(a, b) = shortestPath(a, b, maxDepth 3).length - 1
   frontier A <-- expand smaller side --> frontier B ; stop when the frontiers meet or depth is exhausted
```

## 3. Design decisions and why

- **Store each edge in both users' sets:** "list A's connections" and "is B a connection of A" are single lookups.
- **Bidirectional BFS:** with average degree d, reaching distance 3 one-sidedly touches about d^2 adjacency lists (and sees d^3 users); meeting in the middle touches about 2d lists. On real graphs this is the difference between milliseconds and seconds.
- **Expand the smaller frontier** each step: balances the work when one side is a highly connected user.
- **Deterministic meeting node** (smallest ID) so tests, and users, see a stable path.
- **Fetch counter** stands in for the cost that matters in production: remote adjacency-list reads.
- **Blocks are checked on connect and in PYMK;** a blocked pair is never suggested or reconnected.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

class SocialGraph {
  final _adj = <String, Set<String>>{};
  final _blocked = <String, Set<String>>{};
  var fetches = 0;

  Set<String> friends(String u) {
    fetches++; // one adjacency-list read (a cache or database call in production)
    return _adj[u] ?? const {};
  }

  bool isBlocked(String a, String b) => (_blocked[a]?.contains(b) ?? false) || (_blocked[b]?.contains(a) ?? false);

  bool connect(String a, String b) {
    if (a == b || isBlocked(a, b)) return false;
    final added = _adj.putIfAbsent(a, () => {}).add(b);
    _adj.putIfAbsent(b, () => {}).add(a);
    return added;
  }

  void disconnect(String a, String b) {
    _adj[a]?.remove(b);
    _adj[b]?.remove(a);
  }

  void block(String a, String b) {
    disconnect(a, b);
    _blocked.putIfAbsent(a, () => {}).add(b);
  }

  List<String> mutual(String a, String b) => (friends(a).intersection(friends(b)).toList()..sort());

  /// Shortest path from [a] to [b] with at most [maxDepth] edges, or null.
  List<String>? shortestPath(String a, String b, {int maxDepth = 3}) {
    if (a == b) return [a];
    final parentA = <String, String?>{a: null}, parentB = <String, String?>{b: null};
    var frontierA = {a}, frontierB = {b};
    var depth = 0;
    while (depth < maxDepth && frontierA.isNotEmpty && frontierB.isNotEmpty) {
      final expandA = frontierA.length <= frontierB.length;
      final frontier = expandA ? frontierA : frontierB;
      final parents = expandA ? parentA : parentB, other = expandA ? parentB : parentA;
      final next = <String>{};
      for (final u in frontier) {
        for (final v in friends(u)) {
          if (!parents.containsKey(v)) {
            parents[v] = u;
            next.add(v);
          }
        }
      }
      depth++;
      final meetings = next.where(other.containsKey).toList()..sort();
      if (meetings.isNotEmpty) {
        final m = meetings.first;
        final left = <String>[];
        for (String? x = m; x != null; x = parentA[x]) {
          left.insert(0, x);
        }
        final right = <String>[];
        for (var x = parentB[m]; x != null; x = parentB[x]) {
          right.add(x);
        }
        return [...left, ...right];
      }
      if (expandA) {
        frontierA = next;
      } else {
        frontierB = next;
      }
    }
    return null;
  }

  int? degree(String a, String b, {int maxDepth = 3}) {
    final p = shortestPath(a, b, maxDepth: maxDepth);
    return p == null ? null : p.length - 1;
  }

  /// Baseline: BFS from [a] only.
  int? oneSidedDistance(String a, String b, {int maxDepth = 3}) {
    final dist = <String, int>{a: 0};
    final queue = Queue.of([a]);
    while (queue.isNotEmpty) {
      final u = queue.removeFirst();
      if (u == b) return dist[u];
      if (dist[u]! == maxDepth) continue;
      for (final v in friends(u)) {
        if (!dist.containsKey(v)) {
          dist[v] = dist[u]! + 1;
          if (v == b) return dist[v];
          queue.add(v);
        }
      }
    }
    return null;
  }

  /// Friends of friends ranked by number of mutual connections.
  List<(String, int)> peopleYouMayKnow(String u, {int limit = 10}) {
    final mine = friends(u);
    final counts = <String, int>{};
    for (final f in mine) {
      for (final candidate in friends(f)) {
        if (candidate == u || mine.contains(candidate) || isBlocked(u, candidate)) continue;
        counts[candidate] = (counts[candidate] ?? 0) + 1;
      }
    }
    final ranked = [for (final e in counts.entries) (e.key, e.value)]
      ..sort((x, y) => x.$2 != y.$2 ? y.$2.compareTo(x.$2) : x.$1.compareTo(y.$1));
    return ranked.take(limit).toList();
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final g = SocialGraph();
  for (final (a, b) in [
    ('alice', 'bob'),
    ('bob', 'carol'),
    ('carol', 'dave'),
    ('dave', 'erin'),
    ('alice', 'frank'),
    ('frank', 'carol'),
    ('bob', 'gina'),
  ]) {
    g.connect(a, b);
  }
  check(
    [g.degree('alice', 'bob'), g.degree('alice', 'carol'), g.degree('alice', 'dave'), g.degree('alice', 'erin')],
    [
      1,
      2,
      3,
      null, // 4th degree: beyond the limit
    ],
  );
  check(g.shortestPath('alice', 'dave'), ['alice', 'bob', 'carol', 'dave']);
  check(g.mutual('alice', 'carol'), ['bob', 'frank']);
  check(g.peopleYouMayKnow('alice'), '[(carol, 2), (gina, 1)]');
  check(g.connect('alice', 'alice'), false);

  // Blocking removes the edge, prevents reconnection, and hides suggestions.
  g.block('alice', 'bob');
  check(
    [g.shortestPath('alice', 'bob'), g.connect('bob', 'alice')],
    [
      ['alice', 'frank', 'carol', 'bob'],
      false,
    ],
  ); // only the indirect route is left
  check(g.peopleYouMayKnow('alice'), '[(carol, 1)]'); // gina was only reachable through bob; bob is blocked

  // Random graph: same answers as plain BFS, far fewer adjacency fetches.
  final rng = Random(9);
  final big = SocialGraph();
  const n = 3000;
  for (var i = 0; i < n * 10; i++) {
    big.connect('u${rng.nextInt(n)}', 'u${rng.nextInt(n)}');
  }
  var biFetches = 0, oneFetches = 0, found = 0;
  for (var q = 0; q < 200; q++) {
    final a = 'u${rng.nextInt(n)}', b = 'u${rng.nextInt(n)}';
    big.fetches = 0;
    final d1 = big.degree(a, b);
    biFetches += big.fetches;
    big.fetches = 0;
    final d2 = big.oneSidedDistance(a, b);
    oneFetches += big.fetches;
    if (d1 != d2) throw StateError('distance mismatch for $a, $b: $d1 vs $d2');
    if (d1 != null) found++;
  }
  check(found > 100, true);
  check(biFetches * 5 < oneFetches, true); // bidirectional search did less than a fifth of the work
  print('ok: bidirectional $biFetches fetches vs one-sided $oneFetches');
}
```

## 5. Walkthrough

- Alice reaches Bob directly, Carol through Bob or Frank (2), Dave in 3, and Erin would need 4, so the answer is "beyond 3rd degree".
- The Alice-Dave path meets in the middle; with ties, the alphabetically smallest meeting node gives a stable path through Bob.
- Mutuals of Alice and Carol are Bob and Frank. PYMK for Alice: Carol (2 mutuals) and Gina (1, via Bob).
- After Alice blocks Bob, the edge is gone (the shortest remaining route is 3 hops, through Frank and Carol), Bob cannot reconnect, and Gina disappears from suggestions because her only mutual was Bob.
- On a random graph of 3,000 users with about 20 connections each, 200 random degree queries give the same distances as one-sided BFS while doing under a fifth of the adjacency fetches.

## 6. Concurrency

- Connect/disconnect write two adjacency entries: one transaction when both users are on the same shard; otherwise write both with an idempotent repair job (or a saga) that restores symmetry if one side failed.
- Reads (degree, mutuals) tolerate slightly stale lists; caches are invalidated on edge changes.
- PYMK is computed offline, so it never competes with online traffic.

## 7. Extensibility

| Change | Where |
|---|---|
| Directed follows | Separate `following` and `followers` maps. |
| Super-node cap | Skip or sample nodes with more than N friends during expansion. |
| Cached 2nd-degree sets | Precompute per user; degree 2 becomes a lookup, degree 3 an intersection. |
| Richer PYMK | Add features (same company, contacts) and a ranking model over the candidates. |
| Hide blocked users in traversals | Filter `friends()` results through `isBlocked` for the viewing user. |

## 8. Common mistakes in LLD rounds

- One-sided BFS to depth 3 for every profile view.
- Single-direction edge storage for an undirected relationship.
- Suggesting existing connections or blocked users.
- Non-deterministic paths (different answers for the same query).

See [HLD.md](HLD.md) for storage, caching, PYMK pipelines and super-nodes.
