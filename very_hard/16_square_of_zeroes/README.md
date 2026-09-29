# Square Of Zeroes

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** Precomputed run lengths for O(1) border checks

## Problem
Given an `n x n` matrix of 0s and 1s, return whether it contains a square of side at least 2 whose **border** consists only of 0s (the interior does not matter).

## Building up the logic
1. There are O(n^3) candidate squares (top-left corner x size). Checking each border directly costs O(n): O(n^4) total.
2. **Precompute run lengths:** `right[r][c]` = number of consecutive 0s starting at `(r, c)` going right; `down[r][c]` = going down. Both fill in one backward pass: `right[r][c] = 1 + right[r][c+1]` if the cell is 0.
3. A square with top-left `(r, c)` and side `k` has an all-zero border iff:
   - top edge: `right[r][c] >= k`
   - left edge: `down[r][c] >= k`
   - bottom edge: `right[r + k - 1][c] >= k`
   - right edge: `down[r][c + k - 1] >= k`
4. Each check is O(1), so the total is O(n^3).

## Complexity
- Time: O(n^3).
- Space: O(n^2).

## Interview notes
- Same precomputation as LeetCode #1139 (Largest 1-Bordered Square). AlgoExpert's recursive memoized version (shrinking squares from the outside) is also O(n^4) -> O(n^3) with memoization; the run-length version is simpler to explain.
