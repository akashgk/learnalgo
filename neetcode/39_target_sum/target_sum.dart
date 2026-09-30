// Target Sum: put '+' or '-' before every number; count the assignments whose total is target.
// Let P be the numbers with '+'. Then sum(P) - (S - sum(P)) = target, so sum(P) = (S + target) / 2.
// Count subsets with that sum: 0/1 knapsack counting, iterated backwards. O(n * S) time, O(S) space.

int findTargetSumWays(List<int> nums, int target) {
  final total = nums.fold(0, (a, b) => a + b);
  if (target.abs() > total || (total + target).isOdd) return 0;
  final want = (total + target) ~/ 2;
  final ways = List<int>.filled(want + 1, 0);
  ways[0] = 1; // the empty subset
  for (final x in nums) {
    // Backwards so each number is used at most once. A 0 doubles every count (+0 and -0 differ).
    for (var s = want; s >= x; s--) {
      ways[s] += ways[s - x];
    }
  }
  return ways[want];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(findTargetSumWays([1, 1, 1, 1, 1], 3), 5);
  check(findTargetSumWays([1], 1), 1);
  check(findTargetSumWays([1], 2), 0);
  check(findTargetSumWays([0, 0, 1], 1), 4); // each 0 can be +0 or -0
  check(findTargetSumWays([1, 2, 3], -6), 1); // all minus
}
