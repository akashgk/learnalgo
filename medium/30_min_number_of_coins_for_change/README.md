# Min Number Of Coins For Change

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Unbounded knapsack (minimization)

## Problem
Given a target amount `n` and positive coin denominations (unlimited supply), return the smallest number of coins that sum exactly to `n`, or -1 if impossible. Making 0 takes 0 coins.

## Building up the logic
1. **Why not greedy?** Taking the largest coin first works for US coins but fails in general: `n = 6, coins = [1, 3, 4]` greedy gives `4+1+1` (3 coins), optimal is `3+3` (2 coins). Always test greedy with a counterexample before committing to it.
2. **Subproblem:** `minCoins[a]` = fewest coins to make `a`.
3. **Recurrence:** the last coin used is some `c`, leaving `a - c`. So `minCoins[a] = 1 + min over c of minCoins[a - c]`.
4. Initialize with infinity (unreachable) and `minCoins[0] = 0`. Skip transitions from unreachable states, otherwise `inf + 1` can overflow or create false values.
5. Loop order does not matter for a min (unlike counting in Number Of Ways To Make Change).

## Complexity
- Time: O(n * d).
- Space: O(n).

## Interview notes
- LeetCode #322 (Coin Change). BFS alternative: amounts are nodes, coins are edges, the answer is the shortest path from 0 to n. Same complexity, sometimes faster in practice because it stops early.
