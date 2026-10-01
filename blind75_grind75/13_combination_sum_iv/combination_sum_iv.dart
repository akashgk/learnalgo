// Combination Sum IV: distinct positive nums; count ordered sequences (order matters, reuse allowed)
// that sum to target. dp[t] = sum over x of dp[t - x], with dp[0] = 1: the last number of the
// sequence is any x. O(target * n) time, O(target) space.

int combinationSum4(List<int> nums, int target) {
  final dp = List<int>.filled(target + 1, 0);
  dp[0] = 1; // the empty sequence
  // Totals on the OUTSIDE: every order of the same numbers is counted (sequences, not sets).
  for (var t = 1; t <= target; t++) {
    for (final x in nums) {
      if (x <= t) dp[t] += dp[t - x];
    }
  }
  return dp[target];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(combinationSum4([1, 2, 3], 4), 7); // 1111, 112, 121, 211, 13, 31, 22
  check(combinationSum4([9], 3), 0);
  check(combinationSum4([1], 5), 1);
  check(combinationSum4([2, 3], 7), 3); // 223, 232, 322
}
