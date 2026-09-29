// Sunset Views: buildings facing EAST or WEST can see the sunset if strictly taller than
// every building between them and the sun. Scan from the sun side keeping the running max.
// O(n) time, O(n) output. Returns indices in ascending order.

List<int> sunsetViews(List<int> buildings, String direction) {
  final result = <int>[];
  final facingEast = direction == 'EAST';
  final indices = facingEast
      ? List<int>.generate(buildings.length, (i) => buildings.length - 1 - i) // sun on the right
      : List<int>.generate(buildings.length, (i) => i);
  var tallest = 0;
  for (final i in indices) {
    if (buildings[i] > tallest) {
      result.add(i);
      tallest = buildings[i];
    }
  }
  return facingEast ? result.reversed.toList() : result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const b = [3, 5, 4, 4, 3, 1, 3, 2];
  check(sunsetViews(b, 'EAST'), [1, 3, 6, 7]);
  check(sunsetViews(b, 'WEST'), [0, 1]);
  check(sunsetViews([], 'EAST'), []);
}
