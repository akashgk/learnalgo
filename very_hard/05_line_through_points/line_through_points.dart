// Line Through Points: maximum number of points on one straight line.
// For each anchor point, bucket the others by reduced slope (dy, dx) with gcd normalization.
// O(n^2) time (times log for gcd), O(n) space.

int lineThroughPoints(List<List<int>> points) {
  if (points.length < 3) return points.length;
  var best = 1;
  for (var i = 0; i < points.length; i++) {
    final slopes = <(int, int), int>{};
    for (var j = i + 1; j < points.length; j++) {
      var dx = points[j][0] - points[i][0], dy = points[j][1] - points[i][1];
      final g = _gcd(dx.abs(), dy.abs());
      dx ~/= g;
      dy ~/= g;
      // Canonical sign: dx > 0, or dx == 0 and dy > 0, so (1, 2) and (-1, -2) match.
      if (dx < 0 || (dx == 0 && dy < 0)) {
        dx = -dx;
        dy = -dy;
      }
      final count = slopes.update((dy, dx), (c) => c + 1, ifAbsent: () => 1);
      if (count + 1 > best) best = count + 1; // + the anchor point
    }
  }
  return best;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(lineThroughPoints([[1, 1], [2, 2], [3, 3], [0, 4], [-2, 6], [4, 0], [2, 1]]), 4);
  check(lineThroughPoints([[1, 1]]), 1);
  check(lineThroughPoints([[0, 0], [0, 5], [0, -3], [1, 1]]), 3); // vertical line
  check(lineThroughPoints([[1, 1], [3, 2], [5, 3], [4, 1], [2, 3], [1, 4]]), 4);
}
