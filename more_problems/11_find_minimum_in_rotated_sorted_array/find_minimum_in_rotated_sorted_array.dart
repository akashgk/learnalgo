// Find Minimum in Rotated Sorted Array (distinct values).
// Binary search comparing mid with the right end. O(log n) time, O(1) space.

int findMin(List<int> nums) {
  var lo = 0, hi = nums.length - 1;
  // Invariant: the minimum is always inside [lo, hi].
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (nums[mid] > nums[hi]) {
      // The drop (rotation point) is strictly to the right of mid.
      lo = mid + 1;
    } else {
      // nums[mid..hi] is sorted, so the minimum is at mid or to its left.
      hi = mid;
    }
  }
  return nums[lo];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(findMin([3, 4, 5, 1, 2]), 1);
  check(findMin([4, 5, 6, 7, 0, 1, 2]), 0);
  check(findMin([11, 13, 15, 17]), 11); // not rotated
  check(findMin([2, 1]), 1);
  check(findMin([1]), 1);
}
