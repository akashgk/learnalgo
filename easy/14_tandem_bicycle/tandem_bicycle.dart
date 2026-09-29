// Tandem Bicycle
// A tandem's speed is max(rider speeds). Fastest total: pair fastest with slowest.
// Slowest total: pair fastest with fastest. O(n log n) time.

int tandemBicycle(List<int> redShirtSpeeds, List<int> blueShirtSpeeds, bool fastest) {
  final red = [...redShirtSpeeds]..sort();
  final blue = [...blueShirtSpeeds]..sort();
  if (fastest) blue.sort((a, b) => b - a); // reverse one list to pair opposite ends
  var total = 0;
  for (var i = 0; i < red.length; i++) {
    total += red[i] > blue[i] ? red[i] : blue[i];
  }
  return total;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(tandemBicycle([5, 5, 3, 9, 2], [3, 6, 7, 2, 1], true), 32);
  check(tandemBicycle([5, 5, 3, 9, 2], [3, 6, 7, 2, 1], false), 25);
  check(tandemBicycle([], [], true), 0);
}
