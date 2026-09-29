// Kadane's Algorithm: maximum sum of a non-empty contiguous subarray.
// bestEndingHere = max(x, bestEndingHere + x). O(n) time, O(1) space.

int kadanesAlgorithm(List<int> array) {
  var endingHere = array[0], best = array[0];
  for (var i = 1; i < array.length; i++) {
    final x = array[i];
    endingHere = x > endingHere + x ? x : endingHere + x;
    if (endingHere > best) best = endingHere;
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(kadanesAlgorithm([3, 5, -9, 1, 3, -2, 3, 4, 7, 2, -9, 6, 3, 1, -5, 4]), 19);
  check(kadanesAlgorithm([-1, -2, -3]), -1); // all negative: best single element
  check(kadanesAlgorithm([1, 2, 3]), 6);
}
