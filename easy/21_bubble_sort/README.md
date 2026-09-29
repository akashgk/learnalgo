# Bubble Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Adjacent swaps

## Problem
Sort an array of integers in ascending order using Bubble Sort.

## Building up the logic
1. Scan left to right, swapping any adjacent pair that is out of order. After one pass the largest element is at the end (it "bubbles up").
2. Each pass fixes one more element at the tail, so pass k only needs to go to `n - 1 - k`.
3. If a pass makes zero swaps, the array is sorted: stop. That gives O(n) on already-sorted input.

## Complexity
| Case | Time |
|---|---|
| Best (sorted input, with early exit) | O(n) |
| Average / worst | O(n^2) |

Space O(1). Stable (equal elements are never swapped past each other).

## Interview notes
- You will not be asked to implement Bubble Sort at Google. You may be asked to compare sorts: know stability, in-place-ness, best/average/worst case for bubble, insertion, selection, merge, quick, heap, and radix. The table in the repo root README covers this.
