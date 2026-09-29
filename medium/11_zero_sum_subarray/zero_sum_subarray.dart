// Zero Sum Subarray: does any contiguous non-empty subarray sum to 0?
// If two prefix sums are equal, the elements between them sum to 0.
// O(n) time, O(n) space.

bool zeroSumSubarray(List<int> nums) {
  final seenPrefixSums = <int>{0}; // empty prefix, so a prefix that itself sums to 0 counts
  var sum = 0;
  for (final x in nums) {
    sum += x;
    if (!seenPrefixSums.add(sum)) return true; // add returns false if already present
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(zeroSumSubarray([-5, -5, 2, 3, -2]), true); // -5 + 2 + 3 = 0
  check(zeroSumSubarray([0]), true);
  check(zeroSumSubarray([1, 2, 3]), false);
  check(zeroSumSubarray([]), false);
  check(zeroSumSubarray([4, 2, -1, -1, 3]), true);
}
