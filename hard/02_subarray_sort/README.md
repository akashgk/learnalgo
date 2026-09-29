# Subarray Sort

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Find extremes of the unsorted region

## Problem
Given an integer array (at least two elements), return the start and end indices of the **smallest** subarray that must be sorted in place for the whole array to be sorted ascending. Return `[-1, -1]` if the array is already sorted.

```
[1, 2, 4, 7, 10, 11, 7, 12, 6, 7, 16, 18, 19]  ->  [3, 9]
```

## Building up the logic
1. Sort a copy and compare with the original: the first and last differing indices are the answer. O(n log n), O(n). A fine first answer.
2. Why is the answer not simply "first and last out-of-order positions"? In the example, the first local violation is at index 5/6 (11 > 7), but the 6 at index 8 must move all the way to index 3. The boundaries depend on **where the extreme misplaced values belong**, not where violations appear.
3. So: find the **smallest** and **largest** values among all elements that are out of order relative to a neighbor.
4. The subarray must start at the first position whose value is greater than that smallest misplaced value (that is where it belongs), and end at the last position whose value is smaller than the largest misplaced value.

## Complexity
- Time: O(n), three linear scans.
- Space: O(1).

## Interview notes
- LeetCode #581 (Shortest Unsorted Continuous Subarray). An equivalent O(n) formulation: scan left to right tracking the running max; the last index where `a[i] < runningMax` is the end. Scan right to left tracking the running min; the last index where `a[i] > runningMin` is the start. Very compact; worth knowing both.
