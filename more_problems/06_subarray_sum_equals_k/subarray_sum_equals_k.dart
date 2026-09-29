// Subarray Sum Equals K: count contiguous subarrays whose sum is exactly k.
// Prefix sums + hash map of "how many times has each prefix sum occurred". O(n) time, O(n) space.
// Works with negative numbers (a sliding window does not).

int subarraySum(List<int> nums, int k) {
  final seen = <int, int>{0: 1}; // the empty prefix, so subarrays starting at index 0 count
  var prefix = 0, count = 0;
  for (final x in nums) {
    prefix += x;
    // A subarray (i, j] sums to k exactly when prefix[i] == prefix[j] - k.
    count += seen[prefix - k] ?? 0;
    seen[prefix] = (seen[prefix] ?? 0) + 1;
  }
  return count;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(subarraySum([1, 1, 1], 2), 2);
  check(subarraySum([1, 2, 3], 3), 2); // [1, 2] and [3]
  check(subarraySum([3, 4, 7, 2, -3, 1, 4, 2], 7), 4);
  check(subarraySum([1, -1, 0], 0), 3); // [1, -1], [0], [1, -1, 0]
  check(subarraySum([], 0), 0);
}
