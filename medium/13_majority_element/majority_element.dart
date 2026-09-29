// Majority Element (guaranteed to exist: appears more than n/2 times).
// Boyer-Moore voting. O(n) time, O(1) space.

int majorityElement(List<int> array) {
  var candidate = 0, count = 0;
  for (final x in array) {
    if (count == 0) candidate = x;
    count += x == candidate ? 1 : -1;
  }
  return candidate;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(majorityElement([1, 2, 3, 2, 2, 1, 2]), 2);
  check(majorityElement([1]), 1);
  check(majorityElement([5, 4, 3, 2, 1, 1, 1, 1, 1]), 1);
}
