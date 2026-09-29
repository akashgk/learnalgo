# Search In Sorted Matrix

**Difficulty:** Medium | **Category:** Searching | **Pattern:** Staircase search from a corner

## Problem
Every row and every column of a matrix is sorted ascending (rows are not necessarily continuations of each other). Return `[row, col]` of a target value, or `[-1, -1]` if absent.

## Building up the logic
1. Brute force O(n * m). Binary search each row: O(n log m). Better, but it uses only row sortedness.
2. Look for a corner where the two directions **disagree**: at the top-right, moving left decreases values and moving down increases them. That gives a decision at every step.
3. If the corner is bigger than the target, the entire column below it is also bigger: discard the column (move left). If smaller, the entire row to its left is smaller: discard the row (move down).
4. Each step eliminates a full row or column, so at most `n + m` steps.
5. Starting at the top-left fails: both directions increase, so there is no decision. Bottom-left works equally well.

## Complexity
- Time: O(n + m).
- Space: O(1).

## Interview notes
- LeetCode #240. Contrast with #74, where the matrix is fully sorted in row-major order: treat it as a 1D array and binary search, O(log(n * m)).
