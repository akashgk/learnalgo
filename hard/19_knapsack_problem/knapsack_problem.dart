// 0/1 Knapsack: items [value, weight], capacity. Returns [maxValue, [item indices]].
// DP table best[i][c] over first i items and capacity c, then backtrack.
// O(n * c) time and space.

List<Object> knapsackProblem(List<List<int>> items, int capacity) {
  final n = items.length;
  final best = List.generate(n + 1, (_) => List<int>.filled(capacity + 1, 0));
  for (var i = 1; i <= n; i++) {
    final [value, weight] = items[i - 1];
    for (var c = 0; c <= capacity; c++) {
      best[i][c] = best[i - 1][c]; // skip item i - 1
      if (weight <= c && best[i - 1][c - weight] + value > best[i][c]) {
        best[i][c] = best[i - 1][c - weight] + value; // take it
      }
    }
  }
  final chosen = <int>[];
  var c = capacity;
  for (var i = n; i > 0; i--) {
    if (best[i][c] != best[i - 1][c]) {
      chosen.add(i - 1);
      c -= items[i - 1][1];
    }
  }
  return [best[n][capacity], chosen.reversed.toList()];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(knapsackProblem([[1, 2], [4, 3], [5, 6], [6, 7]], 10), [10, [1, 3]]);
  check(knapsackProblem([[1, 2]], 1), [0, <int>[]]);
  check(knapsackProblem([[465, 100], [400, 85], [255, 55], [350, 45], [650, 130], [1000, 190], [455, 100], [100, 25], [1200, 190], [320, 65], [750, 100], [50, 45], [550, 65], [100, 50], [600, 70], [240, 40]], 200)[0], 1500);
}
