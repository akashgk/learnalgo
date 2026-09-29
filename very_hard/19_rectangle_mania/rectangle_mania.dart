// Rectangle Mania: count axis-aligned rectangles whose 4 corners are in the point set.
// Treat each pair as the diagonal going up-right; check the other two corners.
// O(n^2) time, O(n) space.

int rectangleMania(List<List<int>> coords) {
  final set = {for (final [x, y] in coords) (x, y)};
  var count = 0;
  for (final [x1, y1] in coords) {
    for (final [x2, y2] in coords) {
      // Only count the lower-left -> upper-right diagonal so each rectangle is counted once.
      if (x2 > x1 && y2 > y1 && set.contains((x1, y2)) && set.contains((x2, y1))) count++;
    }
  }
  return count;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(rectangleMania([[0, 0], [0, 1], [1, 1], [1, 0], [2, 1], [2, 0], [3, 1], [3, 0]]), 6);
  check(rectangleMania([[0, 0], [1, 1]]), 0);
  check(rectangleMania([for (var x = 0; x < 3; x++) for (var y = 0; y < 3; y++) [x, y]]), 9);
}
