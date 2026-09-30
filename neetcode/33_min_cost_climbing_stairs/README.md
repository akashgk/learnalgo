# Min Cost Climbing Stairs

**Difficulty:** Easy | **Category:** 1-D Dynamic Programming | **Pattern:** Linear DP with two variables | **Source:** LeetCode 746; NeetCode 150

## The problem

`cost[i]` is the price of stair `i`: once you pay it, you can climb one or two steps up from stair `i`. You may start on stair 0 or stair 1 for free. Return the minimum cost to reach the **top**, the position just past the last stair.

```
[10, 15, 20]                          ->  15   (start at 1, pay 15, climb two to the top)
[1, 100, 1, 1, 1, 100, 1, 1, 100, 1]  ->  6
```

## Step 1: Define the subproblem

Let `dp[i]` = the minimum cost to **stand on** position `i` (without having paid `cost[i]` yet). Positions go from 0 to `n` (the top).

- `dp[0] = dp[1] = 0`: starting there is free.
- To stand on `i`, you came from `i - 1` (paying `cost[i - 1]`) or from `i - 2` (paying `cost[i - 2]`):

```
dp[i] = min(dp[i-1] + cost[i-1], dp[i-2] + cost[i-2])
```

The answer is `dp[n]`.

## Step 2: Brute force

Plain recursion on that formula branches twice at every step: O(2^n). The same `dp[i]` is recomputed many times: memoize, or compute bottom-up.

## Step 3: O(1) space

`dp[i]` only needs the previous two values, so keep two variables. This is the same shape as Fibonacci, Climbing Stairs (AlgoExpert medium 54) and House Robber (AlgoExpert medium 28).

## Step 4: The code

<!-- CODE:START -->

Full source: [`min_cost_climbing_stairs.dart`](min_cost_climbing_stairs.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `twoBack` and `oneBack` hold `dp[i - 2]` and `dp[i - 1]`, both 0 initially.
- The loop runs `i` from 2 to `n` inclusive: `n` is the top.

## Step 5: Dry run

`[10, 15, 20]`:

| i | from i-1 | from i-2 | dp[i] |
|---|---|---|---|
| 0 | | | 0 |
| 1 | | | 0 |
| 2 | 0 + 15 = 15 | 0 + 10 = 10 | 10 |
| 3 (top) | 10 + 20 = 30 | 0 + 15 = 15 | **15** |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Two stairs: the cheaper of the two.
- Zeros: fine.

## Common mistakes

- Returning `dp[n - 1]` (the last stair is not the top).
- Charging the cost of the stair you land on instead of the stair you leave (off by one in the recurrence).

## Follow-ups you should be ready for

1. **Climbing Stairs (count ways).** Replace `min` with `+`.
2. **Up to k steps at a time.** `dp[i] = min over j in 1..k of dp[i-j] + cost[i-j]`; a monotonic deque makes it O(n) (as in more_problems 18).
3. **Return the path.** Store which choice won at each i.

## What to remember

Define `dp[i]` precisely ("cost to stand on i"), write the transition from the last move, and keep only the values the transition reads.
