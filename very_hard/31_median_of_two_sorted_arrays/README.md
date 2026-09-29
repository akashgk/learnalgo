# Median Of Two Sorted Arrays

**Difficulty:** Very Hard | **Category:** Searching | **Pattern:** Binary search on a partition

## Problem
Given two sorted integer arrays (together non-empty), return the median of all their elements combined, in O(log(min(n, m))) time.

## Building up the logic
1. Merge fully and pick the middle: O(n + m). Merge only halfway: still O(n + m).
2. **Reframe:** the median splits the combined sorted list into a left half and a right half. Suppose the left half takes `i` elements from `a` and `j` from `b`, with `i + j = (n + m + 1) / 2`. Choosing `i` determines `j`.
3. The split is correct iff every left element is <= every right element. Since each array is sorted, only the four boundary values matter: `a[i-1] <= b[j]` and `b[j-1] <= a[i]`.
4. If `a[i-1] > b[j]`, `i` is too big; if `b[j-1] > a[i]`, `i` is too small. That monotonicity allows **binary search on i** over the smaller array.
5. Use infinities for out-of-range boundaries (`i == 0`, `i == n`, etc.).
6. Median: odd total -> max of the left boundaries; even -> average of max-left and min-right.

## Complexity
- Time: O(log(min(n, m))).
- Space: O(1).

## Interview notes
- LeetCode #4, a legendary hard problem. The generalization "k-th smallest of two sorted arrays" (discard k/2 elements per step) is an alternative O(log(n + m)) approach and easier to derive under pressure.
- Searching the **smaller** array is what makes `j` always valid (0 <= j <= m); explain that choice.
