// Split Array Largest Sum (also: Book Allocation, Painter's Partition).
// Split nums into k non-empty contiguous parts minimizing the largest part sum.
// Binary search on the answer with a greedy feasibility check. O(n log S) time, O(1) space.

int splitArray(List<int> nums, int k) {
  // The answer lies between the largest single element and the total sum.
  var lo = nums.reduce((a, b) => a > b ? a : b);
  var hi = nums.reduce((a, b) => a + b);
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (_partsNeeded(nums, mid) <= k) {
      hi = mid; // a cap of mid is achievable with at most k parts
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

/// Greedy: fill each part as much as possible without exceeding [cap].
/// Returns the minimum number of parts needed so that no part exceeds [cap].
int _partsNeeded(List<int> nums, int cap) {
  var parts = 1, current = 0;
  for (final x in nums) {
    if (current + x > cap) {
      parts++;
      current = x;
    } else {
      current += x;
    }
  }
  return parts;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(splitArray([7, 2, 5, 10, 8], 2), 18); // [7, 2, 5] [10, 8]
  check(splitArray([1, 2, 3, 4, 5], 2), 9); // [1, 2, 3] [4, 5]
  check(splitArray([1, 4, 4], 3), 4);
  check(splitArray([12, 34, 67, 90], 2), 113); // book allocation classic
  check(splitArray([5], 1), 5);
}
