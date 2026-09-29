// Minimum Area Rectangle (axis-aligned) from a set of points; 0 if none.
// Treat each pair as a diagonal; the other two corners must exist. O(n^2) time, O(n) space.

int minimumAreaRectangle(List<List<int>> points) {
  final set = {for (final [x, y] in points) (x, y)};
  int? best;
  for (var i = 0; i < points.length; i++) {
    final [x1, y1] = points[i];
    for (var j = i + 1; j < points.length; j++) {
      final [x2, y2] = points[j];
      if (x1 == x2 || y1 == y2) continue; // not a diagonal
      if (set.contains((x1, y2)) && set.contains((x2, y1))) {
        final area = (x1 - x2).abs() * (y1 - y2).abs();
        if (best == null || area < best) best = area;
      }
    }
  }
  return best ?? 0;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minimumAreaRectangle([[1, 5], [5, 1], [4, 2], [2, 4], [2, 2], [1, 2], [4, 5], [2, 5], [-1, -2]]), 3);
  check(minimumAreaRectangle([[0, 0], [1, 1]]), 0);
  check(minimumAreaRectangle([[0, 0], [0, 2], [3, 0], [3, 2], [1, 0], [1, 2]]), 2);
}
