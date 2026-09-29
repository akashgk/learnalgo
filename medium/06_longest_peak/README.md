# Longest Peak

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Find anchors, expand outward

## Problem
A peak is a run of adjacent integers that strictly increases to a tip and then strictly decreases, with at least three elements (`[1, 4, 10, 2]` is a peak; `[4, 0, 10]` and `[1, 2, 2, 0]` are not). Return the length of the longest peak, or 0 if there is none.

```
[1, 2, 3, 3, 4, 0, 10, 6, 5, -1, -3, 2, 3]  ->  6   (0, 10, 6, 5, -1, -3)
```

## Building up the logic
1. Every peak has exactly one **tip**: an element strictly greater than both neighbors. Tips are easy to detect locally.
2. From each tip, expand left while strictly increasing (going backwards means strictly decreasing values), and right while strictly decreasing. The span is the peak length.
3. After processing a tip, jump `i` to the end of its descending slope. No tip can exist on a strictly decreasing slope, so no work is skipped incorrectly.
4. Equal adjacent values break peaks: strict comparisons everywhere.

## Complexity
- Time: O(n). Each element is visited at most a constant number of times (once in the scan and at most twice by expansions, since left expansions of consecutive peaks cannot overlap past a valley).
- Space: O(1).

## Interview notes
- Related: LeetCode #845 (Longest Mountain in Array), which also has a DP version: `up[i]` and `down[i]` arrays, answer `max(up[i] + down[i] + 1)` where both are positive.
