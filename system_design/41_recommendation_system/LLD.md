# Recommendation System: Low-Level Design

## 1. Scope for the LLD round

- Record user-item interactions.
- **Item-item collaborative filtering:** cosine similarity from co-occurrence (`co(a, b) / sqrt(|users(a)| x |users(b)|)`), keeping the top neighbors per item.
- **Candidate scoring** for a user: sum of similarities from the items they interacted with, excluding seen items, with an **explanation** (the item that contributed most).
- **Cold start fallback:** most popular items.
- **Diversity re-ranking:** at most N items per category, then fill if short.
- **Offline evaluation:** hit rate at k on held-out interactions, CF vs popularity baseline.

Out of scope: embeddings and ANN, ranking models, feature stores (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Recommendation` | Item, score, reason. |
| `Recommender` | Interactions, similarity table (built offline), `recommend`, `similar`, popularity, re-ranking. |
| `hitRateAtK` | Held-out evaluation. |

```text
interactions: user -> {items}, item -> {users}
build(): co-occurrence counts per item pair -> cosine -> top-N neighbors per item   (the offline job)
recommend(user): candidates = neighbors of the user's items, score = sum of similarities, minus seen
              --> sort --> diversity re-rank (max per category) --> top k   (or popular items if none)
```

## 3. Design decisions and why

- **Item-item rather than user-user:** item relationships are more stable than user tastes, there are fewer items than users to precompute, and explanations come for free.
- **Cosine normalization:** raw co-occurrence would make every item look similar to blockbusters.
- **Top-N neighbors per item:** bounds memory and request-time work (only neighbors of the user's items are touched).
- **Popular fallback:** new users still get reasonable results.
- **Re-ranking separate from scoring:** business rules change often; the model does not.
- **Deterministic tie-breaking** (by item ID) for stable, testable output.

## 4. The code

```dart
import 'dart:math';

class Recommendation {
  const Recommendation(this.item, this.score, this.reason);
  final String item;
  final double score;
  final String reason;
  @override
  String toString() => '$item(${score.toStringAsFixed(3)}, $reason)';
}

class Recommender {
  Recommender({this.neighborsPerItem = 20});
  final int neighborsPerItem;
  final _userItems = <String, Set<String>>{};
  final _itemUsers = <String, Set<String>>{};
  final category = <String, String>{};
  var _neighbors = <String, Map<String, double>>{};

  void record(String user, String item) {
    _userItems.putIfAbsent(user, () => {}).add(item);
    _itemUsers.putIfAbsent(item, () => {}).add(user);
  }

  /// Offline job: cosine similarity from co-occurrence, top neighbors per item.
  void build() {
    final co = <String, Map<String, int>>{};
    for (final items in _userItems.values) {
      final list = items.toList();
      for (var i = 0; i < list.length; i++) {
        for (var j = 0; j < list.length; j++) {
          if (i == j) continue;
          final row = co.putIfAbsent(list[i], () => {});
          row[list[j]] = (row[list[j]] ?? 0) + 1;
        }
      }
    }
    _neighbors = {
      for (final MapEntry(key: a, value: row) in co.entries)
        a: Map.fromEntries(
          (row.entries
                  .map((e) => MapEntry(e.key, e.value / sqrt(_itemUsers[a]!.length * _itemUsers[e.key]!.length)))
                  .toList()
                ..sort((x, y) => x.value != y.value ? y.value.compareTo(x.value) : x.key.compareTo(y.key)))
              .take(neighborsPerItem),
        ),
    };
  }

  double similarity(String a, String b) => _neighbors[a]?[b] ?? 0;

  List<String> popular({Set<String> exclude = const {}}) =>
      (_itemUsers.keys.where((i) => !exclude.contains(i)).toList()..sort((a, b) {
        final d = _itemUsers[b]!.length - _itemUsers[a]!.length;
        return d != 0 ? d : a.compareTo(b);
      }));

  List<Recommendation> similar(String item, {int k = 5}) => [
    for (final e in (_neighbors[item] ?? const <String, double>{}).entries.take(k))
      Recommendation(e.key, e.value, 'similar to $item'),
  ];

  List<Recommendation> recommend(String user, {int k = 10, int? maxPerCategory}) {
    final seen = _userItems[user] ?? const <String>{};
    final score = <String, double>{};
    final best = <String, (String, double)>{}; // candidate -> (source item, contribution)
    for (final s in seen) {
      for (final MapEntry(key: cand, value: sim) in (_neighbors[s] ?? const <String, double>{}).entries) {
        if (seen.contains(cand)) continue;
        score[cand] = (score[cand] ?? 0) + sim;
        if (sim > (best[cand]?.$2 ?? -1)) best[cand] = (s, sim);
      }
    }
    if (score.isEmpty) {
      return [
        for (final i in popular(exclude: seen).take(k)) Recommendation(i, _itemUsers[i]!.length.toDouble(), 'popular'),
      ];
    }
    final ranked = [for (final e in score.entries) Recommendation(e.key, e.value, 'because of ${best[e.key]!.$1}')]
      ..sort((a, b) => a.score != b.score ? b.score.compareTo(a.score) : a.item.compareTo(b.item));
    return maxPerCategory == null ? ranked.take(k).toList() : _diversify(ranked, k, maxPerCategory);
  }

  /// Greedy: take items in score order unless their category is full; fill from the skipped ones if short.
  List<Recommendation> _diversify(List<Recommendation> ranked, int k, int maxPerCategory) {
    final picked = <Recommendation>[], skipped = <Recommendation>[];
    final perCategory = <String, int>{};
    for (final r in ranked) {
      if (picked.length == k) break;
      final c = category[r.item] ?? '';
      if ((perCategory[c] ?? 0) >= maxPerCategory) {
        skipped.add(r);
        continue;
      }
      perCategory[c] = (perCategory[c] ?? 0) + 1;
      picked.add(r);
    }
    for (final r in skipped) {
      if (picked.length == k) break;
      picked.add(r);
    }
    return picked;
  }
}

/// Fraction of users whose held-out item appears in their top [k].
double hitRateAtK(Map<String, String> heldOut, List<String> Function(String user) top, int k) =>
    heldOut.entries.where((e) => top(e.key).take(k).contains(e.value)).length / heldOut.length;

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final r = Recommender();
  for (final (u, items) in [
    ('u1', ['A', 'B', 'C']),
    ('u2', ['A', 'B']),
    ('u3', ['B', 'C']),
    ('u4', ['A', 'D']),
    ('u5', ['A']),
  ]) {
    for (final i in items) {
      r.record(u, i);
    }
  }
  r.category.addAll({'A': 'comedy', 'B': 'comedy', 'C': 'drama', 'D': 'comedy'});
  r.build();

  // Cosine similarities: A and B co-occur for 2 of 4 A-users and 3 B-users.
  check(
    [
      for (final p in [('A', 'B'), ('B', 'C'), ('A', 'D')]) r.similarity(p.$1, p.$2).toStringAsFixed(3),
    ],
    ['0.577', '0.816', '0.500'],
  );
  check(r.recommend('u5', k: 3), '[B(0.577, because of A), D(0.500, because of A), C(0.354, because of A)]');
  check(r.recommend('u4', k: 2).map((x) => x.item), '(B, C)'); // from A and D
  check(r.similar('B', k: 2).map((x) => x.item), '(C, A)');

  // Cold start: a brand-new user gets popular items.
  check(r.recommend('newbie', k: 3).map((x) => '${x.item}:${x.reason}'), '(A:popular, B:popular, C:popular)');

  // Diversity: at most one comedy in a list of two.
  check(r.recommend('u5', k: 2, maxPerCategory: 1).map((x) => x.item), '(B, C)');

  // Offline evaluation on synthetic taste clusters: CF beats popularity by a wide margin.
  final rng = Random(5);
  const genres = ['scifi', 'romance', 'horror'];
  final eval = Recommender();
  final heldOut = <String, String>{};
  for (var u = 0; u < 300; u++) {
    final g = genres[u % 3];
    final liked = <int>{};
    while (liked.length < 8) {
      liked.add(rng.nextInt(20));
    }
    final items = [for (final i in liked) '$g-$i'];
    heldOut['user$u'] = items.removeLast();
    for (final i in items) {
      eval.record('user$u', i);
    }
    eval.record('user$u', 'blockbuster-${rng.nextInt(3)}'); // everyone also watches a few blockbusters
  }
  eval.build();
  final cf = hitRateAtK(heldOut, (u) => eval.recommend(u, k: 10).map((x) => x.item).toList(), 10);
  final pop = hitRateAtK(heldOut, (u) => eval.popular(exclude: {...?eval._userItems[u]}).toList(), 10);
  check(cf > 2 * pop && cf > 0.5, true);
  print('ok: hit rate@10 collaborative filtering ${cf.toStringAsFixed(2)} vs popularity ${pop.toStringAsFixed(2)}');
}
```

## 5. Walkthrough

- A is used by u1, u2, u4 and u5 (4 users); B by u1, u2, u3 (3). They co-occur twice: 2 / sqrt(4 x 3) = 0.577. B and C: 2 / sqrt(3 x 2) = 0.816. A and D: 1 / sqrt(4 x 1) = 0.5.
- u5 has only A: B (0.577), D (0.5), and C, which co-occurs with A only through u1: 1 / sqrt(4 x 2) ≈ 0.354. Each explanation names A.
- u4 (A, D): candidates B and C, both because of A.
- A user with no history gets the most popular items.
- With at most one comedy, u5's list becomes B (comedy) then C (drama); D (comedy) is skipped.
- Synthetic evaluation: 300 users in three taste clusters plus shared blockbusters. Collaborative filtering puts the held-out item in the top 10 for most users; the popularity list (dominated by blockbusters and items liked across clusters) rarely does.

## 6. Concurrency

- The similarity table is built offline and swapped in as an immutable map; serving reads it without locks.
- Interaction recording at serving time goes to a log/stream (Kafka), not into the live table; real-time signals use a separate recent-history store.
- Requests are independent and parallel; the expensive part (ranking) is batched.

## 7. Extensibility

| Change | Where |
|---|---|
| Embeddings + ANN candidates | Another candidate source merged before scoring. |
| Ranking model | Replace the sum of similarities with model scores over the candidate set. |
| Implicit feedback weights | Weight interactions (watch time, purchase > click) in co-occurrence. |
| Time decay | Older interactions contribute less to the user's candidate scores. |
| Exploration | Reserve slots for new items with uncertain scores. |

## 8. Common mistakes in LLD rounds

- Recommending items the user already consumed.
- Raw co-occurrence counts (everything is "similar" to the most popular item).
- No fallback for users with no history.
- Evaluating on training data (no held-out items).

See [HLD.md](HLD.md) for the funnel, feature stores, training pipelines and A/B testing.
