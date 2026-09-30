// Min Cost Climbing Stairs: paying cost[i] lets you climb 1 or 2 steps up from stair i.
// Start at stair 0 or 1 for free; reach the top (one past the last stair) for the least cost.
// dp[i] = cheapest way to stand at i = min(dp[i-1] + cost[i-1], dp[i-2] + cost[i-2]).
// O(n) time, O(1) space with two variables.

int minCostClimbingStairs(List<int> cost) {
  var twoBack = 0, oneBack = 0; // dp[0] = dp[1] = 0: starting on stair 0 or 1 is free
  for (var i = 2; i <= cost.length; i++) {
    final a = oneBack + cost[i - 1], b = twoBack + cost[i - 2];
    final here = a < b ? a : b;
    twoBack = oneBack;
    oneBack = here;
  }
  return oneBack; // dp[n]: standing on the top
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minCostClimbingStairs([10, 15, 20]), 15); // start at 1, jump two to the top
  check(minCostClimbingStairs([1, 100, 1, 1, 1, 100, 1, 1, 100, 1]), 6);
  check(minCostClimbingStairs([0, 0]), 0);
  check(minCostClimbingStairs([5, 3]), 3); // leaving any stair costs its price: pay 3 on stair 1
}
