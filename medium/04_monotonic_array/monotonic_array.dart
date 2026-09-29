// Monotonic Array: entirely non-increasing or entirely non-decreasing.
// Track both possibilities in one pass. O(n) time, O(1) space.

bool isMonotonic(List<int> array) {
  var nonDecreasing = true, nonIncreasing = true;
  for (var i = 1; i < array.length; i++) {
    if (array[i] < array[i - 1]) nonDecreasing = false;
    if (array[i] > array[i - 1]) nonIncreasing = false;
    if (!nonDecreasing && !nonIncreasing) return false;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isMonotonic([-1, -5, -10, -1100, -1100, -1101, -1102, -9001]), true);
  check(isMonotonic([1, 1, 2, 3, 4, 5, 5, 5, 6, 7, 8, 7, 9, 10, 11]), false);
  check(isMonotonic([]), true);
  check(isMonotonic([1, 1, 1]), true);
}
