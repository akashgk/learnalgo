# Social News with Voting and Comments: Low-Level Design

## 1. Scope for the LLD round

- **Votes:** one per (user, item) with values up (+1), down (-1) or none (0); repeating a vote does nothing; changing a vote applies the delta; author **karma** follows.
- **Hot ranking** for posts (Reddit's formula): logarithm of the net score plus a time term (45,000 s = 12.5 h per factor of 10 votes).
- **Best ranking** for comments: the lower bound of the **Wilson score interval** (95%).
- **Comment trees:** children per parent, sorted by best; rendered with a per-level limit and depth limit, with "load more" placeholders.
- Community **front page** by hot.

Out of scope: storage, caching, anti-abuse (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Item` | A post or comment: author, time, ups, downs, parent. |
| `hotScore`, `wilsonLowerBound` | Ranking functions. |
| `Forum` | Items, votes (idempotent with deltas), karma, front page, thread rendering. |

```text
Forum: items{id -> Item}, votes{(user, item) -> -1|0|+1}, children{parent -> [comment IDs]}
vote(u, i, dir): delta = dir - old -> ups/downs/karma adjusted once
frontPage = posts sorted by hotScore(ups, downs, createdAt)
renderThread(post) = DFS over children sorted by wilsonLowerBound, top N per level, "load more (k)"
```

## 3. Design decisions and why

- **Store the vote, apply the delta:** the vote table is the truth and makes votes idempotent; counters change by exactly `new - old`.
- **Hot uses the post's creation time,** not "now": the score only changes when votes change, so it can be stored in a sorted index and updated incrementally.
- **Logarithmic votes:** early votes matter most; a post needs 10x the votes to keep up with one posted 12.5 hours later.
- **Wilson lower bound for comments:** penalizes small samples (1 up, 0 down is not "100% good"), so the best-confirmed comments rise.
- **Lazy rendering of trees:** big threads are never loaded whole.

## 4. The code

```dart
import 'dart:math';

const redditEpoch = 1134028003; // Reddit's reference time (seconds)

double hotScore(int ups, int downs, int createdAtSec) {
  final s = ups - downs;
  final order = log(max(s.abs(), 1)) / ln10;
  final sign = s > 0 ? 1 : (s < 0 ? -1 : 0);
  return sign * order + (createdAtSec - redditEpoch) / 45000;
}

/// Lower bound of the Wilson score interval for the upvote fraction (z = 1.96 for 95%).
double wilsonLowerBound(int ups, int downs, {double z = 1.96}) {
  final n = ups + downs;
  if (n == 0) return 0;
  final p = ups / n;
  return (p + z * z / (2 * n) - z * sqrt((p * (1 - p) + z * z / (4 * n)) / n)) / (1 + z * z / n);
}

class Item {
  Item(this.id, this.author, this.createdAt, this.text, {this.parentId});
  final String id;
  final String author;
  final int createdAt;
  final String text;
  final String? parentId; // null for posts
  int ups = 0;
  int downs = 0;
  int get score => ups - downs;
}

class Forum {
  final items = <String, Item>{};
  final _votes = <(String, String), int>{};
  final karma = <String, int>{};
  final _children = <String, List<String>>{};
  var _next = 1;

  Item post(String author, String title, int at) {
    final id = 'p${_next++}';
    return items[id] = Item(id, author, at, title);
  }

  Item comment(String author, String parentId, String text, int at) {
    final c = Item('c${_next++}', author, at, text, parentId: parentId);
    items[c.id] = c;
    _children.putIfAbsent(parentId, () => []).add(c.id);
    return c;
  }

  void vote(String user, String itemId, int direction) {
    if (direction < -1 || direction > 1) throw ArgumentError('vote must be -1, 0 or 1');
    final item = items[itemId]!;
    final old = _votes[(user, itemId)] ?? 0;
    if (old == direction) return; // idempotent
    _votes[(user, itemId)] = direction;
    item
      ..ups += (direction == 1 ? 1 : 0) - (old == 1 ? 1 : 0)
      ..downs += (direction == -1 ? 1 : 0) - (old == -1 ? 1 : 0);
    karma[item.author] = (karma[item.author] ?? 0) + direction - old;
  }

  List<String> frontPage({int limit = 25}) {
    final posts = items.values.where((i) => i.parentId == null).toList()
      ..sort((a, b) => hotScore(b.ups, b.downs, b.createdAt).compareTo(hotScore(a.ups, a.downs, a.createdAt)));
    return [for (final p in posts.take(limit)) p.text];
  }

  List<String> renderThread(String postId, {int perLevel = 2, int maxDepth = 3}) {
    final lines = <String>[];
    void walk(String parent, int depth) {
      final kids = [...?_children[parent]]
        ..sort((a, b) {
          final x = items[a]!, y = items[b]!;
          final d = wilsonLowerBound(y.ups, y.downs).compareTo(wilsonLowerBound(x.ups, x.downs));
          return d != 0 ? d : a.compareTo(b);
        });
      if (kids.isEmpty) return;
      if (depth > maxDepth) {
        lines.add('${'  ' * depth}[continue thread: ${kids.length} replies]');
        return;
      }
      for (final id in kids.take(perLevel)) {
        final c = items[id]!;
        lines.add('${'  ' * depth}${c.text} (+${c.ups}/-${c.downs})');
        walk(id, depth + 1);
      }
      if (kids.length > perLevel) lines.add('${'  ' * depth}[load ${kids.length - perLevel} more]');
    }

    walk(postId, 0);
    return lines;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final f = Forum();
  const t0 = 1700000000;
  final p = f.post('alice', 'Show HN: my project', t0);

  // Votes are idempotent; changes apply the delta; karma follows.
  f
    ..vote('bob', p.id, 1)
    ..vote('bob', p.id, 1);
  check([p.ups, p.downs, f.karma['alice']], [1, 0, 1]);
  f.vote('bob', p.id, -1);
  check([p.ups, p.downs, f.karma['alice']], [0, 1, -1]);
  f.vote('bob', p.id, 0);
  check([p.score, f.karma['alice']], [0, 0]);

  // Hot: 10x the votes is worth 12.5 hours.
  final h100 = hotScore(100, 0, t0), h10 = hotScore(10, 0, t0 + 45000);
  check((h100 - h10).abs() < 1e-9, true);
  check(hotScore(5, 0, t0) > hotScore(0, 5, t0), true); // negative scores sink

  // Front page: a fresh post with fewer votes can beat an old popular one.
  final old = f.post('carol', 'Old but popular', t0 - 24 * 3600);
  final fresh = f.post('dave', 'Fresh and rising', t0);
  for (var i = 0; i < 200; i++) {
    f.vote('u$i', old.id, 1);
  }
  for (var i = 0; i < 20; i++) {
    f.vote('v$i', fresh.id, 1);
  }
  check(f.frontPage(limit: 2), ['Fresh and rising', 'Old but popular']); // 200 votes a day ago < 20 now

  // Wilson lower bound: confidence beats a perfect but tiny ratio.
  check(
    [wilsonLowerBound(1, 0).toStringAsFixed(4), wilsonLowerBound(100, 10).toStringAsFixed(4), wilsonLowerBound(0, 0)],
    ['0.2065', '0.8407', 0.0],
  );

  // Comment tree: children ordered by best, two per level, deeper levels collapsed.
  final c1 = f.comment('e', fresh.id, 'one perfect vote', t0 + 10);
  final c2 = f.comment('f', fresh.id, 'well supported', t0 + 20);
  final c3 = f.comment('g', fresh.id, 'controversial', t0 + 30);
  f.vote('x', c1.id, 1);
  for (var i = 0; i < 50; i++) {
    f.vote('y$i', c2.id, 1);
  }
  for (var i = 0; i < 5; i++) {
    f
      ..vote('z$i', c3.id, 1)
      ..vote('w$i', c3.id, -1);
  }
  var parent = c2.id;
  for (var depth = 0; depth < 5; depth++) {
    parent = f.comment('h', parent, 'reply depth ${depth + 1}', t0 + 40 + depth).id;
  }
  check(f.renderThread(fresh.id, maxDepth: 2), [
    'well supported (+50/-0)',
    '  reply depth 1 (+0/-0)',
    '    reply depth 2 (+0/-0)',
    '      [continue thread: 1 replies]',
    'controversial (+5/-5)',
    '[load 1 more]',
  ]);
}
```

## 5. Walkthrough

- Bob upvotes twice (counted once), switches to a downvote (score moves by 2), then removes his vote: everything returns to zero, including Alice's karma.
- A post with 100 votes and one with 10 votes posted 45,000 seconds later have the same hot score: log10(100) = 2 = log10(10) + 1.
- A post from 24 hours ago with 200 votes (log10 200 ≈ 2.3) loses to a fresh post with 20 votes (log10 20 ≈ 1.3 plus 86,400 / 45,000 ≈ 1.92 of time advantage).
- Wilson: 1 up and 0 down gives 0.21; 100 up and 10 down gives 0.84, so the well-supported comment ranks higher.
- In the thread, "well supported" comes first, then "controversial" (5/5: 0.24) and "one perfect vote" (0.21) is behind a "load 1 more" link. The reply chain under "well supported" is shown down to depth 2 and then collapsed.

## 6. Concurrency

- Votes: the (user, item) row upsert returns the old value; the delta is applied to counters (atomic increments or a stream aggregator). Two concurrent votes by the same user are serialized on that row.
- Counters may lag; the hot index is updated from the aggregated counters, not per vote.
- Thread rendering reads possibly slightly stale counts; caches per thread are invalidated on a short timer.

## 7. Extensibility

| Change | Where |
|---|---|
| Hacker News ranking | `(points - 1) / (ageHours + 2)^1.8`, recomputed periodically. |
| Controversial sort | Score by total votes x balance (min(ups, downs) / max(ups, downs)). |
| Vote weighting | Multiply each vote by an account trust factor. |
| Persisted trees | Materialized paths for subtree queries. |

## 8. Common mistakes in LLD rounds

- Incrementing counters on every vote call without remembering the user's previous vote.
- Ranking comments by net score or plain ratio.
- Hot formulas that depend on "now" but are stored as if static.

See [HLD.md](HLD.md) for counters at scale, listings and abuse prevention.
