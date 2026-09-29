# Knapsack Problem

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 0/1 knapsack

## Problem
Given items as `[value, weight]` pairs and a knapsack capacity, choose a subset (each item at most once) whose total weight fits and whose total value is maximal. Return `[maxValue, [indices of chosen items]]`.

## Building up the logic
1. Brute force: all 2^n subsets.
2. Greedy by value/weight ratio fails for 0/1 knapsack (it is correct only for the fractional version). Counterexample: capacity 10, items A = (value 7, weight 6), B = (5, 5), C = (5, 5). Greedy takes A first (best ratio 1.17), then nothing else fits: value 7. Optimal is B + C: value 10. Always have a counterexample ready when rejecting greedy.
3. **Subproblem:** `best[i][c]` = best value using only the first `i` items with capacity `c`.
4. **Recurrence (take or skip item i):**
   `best[i][c] = max(best[i-1][c], best[i-1][c - w_i] + v_i)` (second option only if `w_i <= c`).
5. **Reconstruct:** walk back from `(n, capacity)`. If `best[i][c] != best[i-1][c]`, item `i-1` was taken; subtract its weight.
6. **Space:** a single 1D array works if you iterate capacity **downward** (so each item is used at most once). Iterating upward turns it into the unbounded knapsack. Reconstruction then needs extra bookkeeping.

## Complexity
- Time: O(n * c).
- Space: O(n * c) with reconstruction; O(c) for value only.
- This is **pseudo-polynomial**: polynomial in the numeric value of capacity, not in its bit length. Knapsack is NP-hard. Saying this is a good signal.

## Interview notes
- Variants: subset sum / partition equal subset sum (#416), target sum (#494), ones and zeroes (#474, 2D capacity), coin change (unbounded, see medium section).
