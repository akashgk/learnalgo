// Count Squares: number of squares (any rotation) whose 4 corners are among the points.
// For each pair treated as a diagonal, compute the other two corners and check the set.
// Each square is found twice (two diagonals). Doubled coordinates avoid fractions.
// O(n^2) time, O(n) space.

int countSquares(List<List<int>> points) {
  final set = {for (final [x, y] in points) (2 * x, 2 * y)};
  final p = [for (final [x, y] in points) (2 * x, 2 * y)];
  var count = 0;
  for (var i = 0; i < p.length; i++) {
    for (var j = i + 1; j < p.length; j++) {
      final (x1, y1) = p[i];
      final (x2, y2) = p[j];
      final mx = (x1 + x2) ~/ 2, my = (y1 + y2) ~/ 2; // exact: coordinates are doubled
      final dx = x1 - mx, dy = y1 - my; // half-diagonal vector
      final c = (mx - dy, my + dx), d = (mx + dy, my - dx); // rotate by 90 degrees
      if (set.contains(c) && set.contains(d)) count++;
    }
  }
  return count ~/ 2;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    countSquares([
      [1, 1],
      [0, 0],
      [-4, 2],
      [-2, -1],
      [0, 1],
      [1, 0],
      [-1, 4],
    ]),
    2,
  );
  check(
    countSquares([
      [0, 0],
      [0, 1],
      [1, 1],
      [1, 0],
    ]),
    1,
  );
  check(
    countSquares([
      [0, 0],
      [1, 1],
    ]),
    0,
  );
  // 2x2 grid of unit squares plus the big square plus one tilted square: 3x3 lattice has 6
  check(
    countSquares([
      for (var x = 0; x < 3; x++)
        for (var y = 0; y < 3; y++) [x, y],
    ]),
    6,
  );
}
