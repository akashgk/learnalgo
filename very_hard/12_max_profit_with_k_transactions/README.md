# Max Profit With K Transactions

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** 2D DP with a running-max optimization

## Problem
Given daily stock prices and an integer k, return the maximum profit from at most k transactions (a transaction is buy then sell; you can hold at most one share at a time).

```
prices = [5, 11, 3, 50, 60, 90], k = 2  ->  93   (buy 5 sell 11, buy 3 sell 90)
```

## Building up the logic
1. **Subproblem:** `P[t][d]` = max profit using at most `t` transactions by day `d`.
2. **Choice on day d:** do nothing (`P[t][d-1]`), or sell on day d a share bought on some earlier day `x`, where before `x` you used at most `t-1` transactions: `prices[d] - prices[x] + P[t-1][x]`.
3. Naively that inner max over `x` makes it O(k * n^2).
4. **Optimization:** `max over x < d of (P[t-1][x] - prices[x])` only gains one new candidate per day. Keep it as a running variable (`bestBuy`). O(k * n).
5. Only row `t - 1` is needed to compute row `t`: two rows, O(n) space.
6. If `k >= n / 2`, the limit never binds: sum every positive day-to-day increase (O(n)). Mention this shortcut; it prevents huge k from blowing up the table.

## Complexity
- Time: O(n * k).
- Space: O(n).

## Interview notes
- LeetCode #188 (Best Time to Buy and Sell Stock IV). The whole family (#121 one transaction, #122 unlimited, #123 two, #309 cooldown, #714 fee) is best unified as a state machine: hold / not-hold per transaction count. Interviewers frequently walk up this ladder.
