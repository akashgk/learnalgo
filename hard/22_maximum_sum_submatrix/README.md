# Maximum Sum Submatrix

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 2D prefix sums

## Problem
Given a 2D integer matrix (values may be negative) and a positive `size`, return the maximum sum of any `size x size` submatrix. The size never exceeds the matrix dimensions.

## Building up the logic
1. Brute force: for each of the O(w * h) positions, sum `size^2` cells. O(w * h * size^2).
2. **1D warm-up:** with prefix sums `P[i] = a[0] + ... + a[i-1]`, any range sum is `P[j] - P[i]` in O(1).
3. **2D prefix sums:** `P[r][c]` = sum of the rectangle from `(0,0)` to `(r-1, c-1)`. Build it with inclusion-exclusion:
   `P[r+1][c+1] = a[r][c] + P[r][c+1] + P[r+1][c] - P[r][c]` (the top-left block was added twice).
4. Any rectangle with bottom-right corner `(r, c)` (exclusive) and side `size`:
   `P[r][c] - P[r-size][c] - P[r][c-size] + P[r-size][c-size]`.
5. Padding the prefix table with a zero row and column removes all boundary special cases.

## Complexity
- Time: O(w * h).
- Space: O(w * h).

## Interview notes
- 2D prefix sums appear in LeetCode #304 (Range Sum Query 2D) and #1314 (Matrix Block Sum). For **any size** max-sum rectangle, fix a pair of rows and run Kadane on column sums: O(rows^2 * cols).
