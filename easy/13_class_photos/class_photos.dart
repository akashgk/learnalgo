// Class Photos
// Sort both colors; the back row is whichever group has the taller tallest student.
// Every back student must be strictly taller than the student in front. O(n log n) time.

bool classPhotos(List<int> redShirtHeights, List<int> blueShirtHeights) {
  final red = [...redShirtHeights]..sort((a, b) => b - a);
  final blue = [...blueShirtHeights]..sort((a, b) => b - a);
  final redInBack = red[0] > blue[0];
  final (back, front) = redInBack ? (red, blue) : (blue, red);
  for (var i = 0; i < back.length; i++) {
    if (back[i] <= front[i]) return false;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(classPhotos([5, 8, 1, 3, 4], [6, 9, 2, 4, 5]), true);
  check(classPhotos([6, 9, 2, 4, 5], [5, 8, 1, 3, 4]), true);
  check(classPhotos([6, 9, 2, 4, 5, 1], [5, 8, 1, 3, 4, 9]), false);
  check(classPhotos([5], [5]), false);
}
