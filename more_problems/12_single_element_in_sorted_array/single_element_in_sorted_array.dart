// Single Element in a Sorted Array: every value appears twice except one. Find it.
// Binary search on pair alignment: before the single element, pairs start at even indices;
// after it, at odd indices. O(log n) time, O(1) space.

int singleNonDuplicate(List<int> nums) {
  var lo = 0, hi = nums.length - 1;
  while (lo < hi) {
    var mid = lo + (hi - lo) ~/ 2;
    if (mid.isOdd) mid--; // look at the pair that should start at an even index
    if (nums[mid] == nums[mid + 1]) {
      // Pairing is still intact up to mid + 1: the single element is to the right.
      lo = mid + 2;
    } else {
      // Pairing is already broken at mid: the single element is mid or to its left.
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
  check(singleNonDuplicate([1, 1, 2, 3, 3, 4, 4, 8, 8]), 2);
  check(singleNonDuplicate([3, 3, 7, 7, 10, 11, 11]), 10);
  check(singleNonDuplicate([1]), 1);
  check(singleNonDuplicate([1, 2, 2]), 1);
  check(singleNonDuplicate([1, 1, 2]), 2);
}
