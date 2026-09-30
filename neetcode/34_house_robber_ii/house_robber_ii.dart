// House Robber II: houses in a CIRCLE; adjacent houses cannot both be robbed, and the first and last
// houses are adjacent. Maximize the loot.
// The first and last house cannot both be taken, so the answer is the better of two straight-line
// problems: houses 0..n-2 and houses 1..n-1. O(n) time, O(1) space.

int rob(List<int> nums) {
  if (nums.length == 1) return nums[0];
  final skipLast = _robLine(nums, 0, nums.length - 2);
  final skipFirst = _robLine(nums, 1, nums.length - 1);
  return skipLast > skipFirst ? skipLast : skipFirst;
}

/// House Robber I on nums[lo..hi]: best = max(skip this house, take it + best two back).
int _robLine(List<int> nums, int lo, int hi) {
  var twoBack = 0, oneBack = 0;
  for (var i = lo; i <= hi; i++) {
    final take = twoBack + nums[i];
    final here = take > oneBack ? take : oneBack;
    twoBack = oneBack;
    oneBack = here;
  }
  return oneBack;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(rob([2, 3, 2]), 3); // 2 + 2 is forbidden: first and last touch
  check(rob([1, 2, 3, 1]), 4);
  check(rob([1, 2, 3]), 3);
  check(rob([5]), 5);
  check(rob([2, 7, 9, 3, 1]), 11); // 2 + 9 (the straight-line answer 12 uses both ends)
}
