// Number Of Ways To Traverse Graph: moves only right or down in a width x height grid.
// DP: ways[r][c] = ways[r-1][c] + ways[r][c-1]; rolling row. O(w * h) time, O(w) space.
// Combinatorics alternative: C((w-1) + (h-1), w-1).

int numberOfWaysToTraverseGraph(int width, int height) {
  final row = List<int>.filled(width, 1); // first row: one way to each cell
  for (var r = 1; r < height; r++) {
    for (var c = 1; c < width; c++) {
      row[c] += row[c - 1]; // from above (old row[c]) + from left (row[c-1])
    }
  }
  return row[width - 1];
}

int numberOfWaysMath(int width, int height) {
  // C(n, k) computed incrementally; each intermediate value is an exact integer.
  final n = width + height - 2, k = width - 1 < height - 1 ? width - 1 : height - 1;
  var result = 1;
  for (var i = 1; i <= k; i++) {
    result = result * (n - k + i) ~/ i;
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(numberOfWaysToTraverseGraph(4, 3), 10);
  check(numberOfWaysMath(4, 3), 10);
  check(numberOfWaysToTraverseGraph(1, 1), 1);
  check(numberOfWaysMath(10, 10), numberOfWaysToTraverseGraph(10, 10));
}
