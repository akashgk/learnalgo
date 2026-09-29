# Juice Bottling

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Rod cutting (unbounded knapsack on size)

## Problem
`prices[i]` is the selling price of a bottle containing `i` units of juice (`prices[0] = 0`). You have `prices.length - 1` units and must bottle all of it. Return the list of bottle sizes that maximizes total revenue (sorted ascending here). Assume a unique optimum.

## Building up the logic
1. This is the textbook **rod cutting** problem (CLRS chapter 15).
2. **Subproblem:** `best[u]` = max revenue from exactly `u` units.
3. **Recurrence:** choose the size `s` of one bottle, then optimally bottle the rest: `best[u] = max over s in 1..u of prices[s] + best[u - s]`.
4. Record the chosen `s` for each `u` (`firstBottle[u]`), then reconstruct by repeatedly subtracting.
5. Greedy by price-per-unit fails. Counterexample: `prices = [0, 1, 6, 10, 11]` (4 units). Size 3 has the best ratio (3.33), so greedy sells 3 + 1 for 10 + 1 = 11. Optimal is 2 + 2 for 6 + 6 = 12. The best-ratio size can leave an awkward remainder.

## Complexity
- Time: O(n^2).
- Space: O(n).

## Edge case
Initialize each amount with the single-bottle option (`best[u] = prices[u]`, `firstBottle[u] = u`). If you start from 0 and only update on strict improvement, inputs where nothing beats 0 (all prices 0) leave `firstBottle[u] = 0`, and reconstruction subtracts 0 forever. A randomized brute-force comparison caught exactly this bug in an earlier draft of this solution.

## Interview notes
- Rod cutting is the canonical example used to teach the difference between memoization and bottom-up DP. It is also unbounded knapsack where "weight" is size and the capacity must be filled exactly.
