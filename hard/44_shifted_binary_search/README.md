# Shifted Binary Search

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Binary search on a rotated array

## Problem
A sorted array of distinct integers has been rotated (shifted) by some unknown amount, e.g. `[45, 61, 71, 72, 73, 0, 1, 21, 33, 37]`. Return the index of a target, or -1, in O(log n).

## Building up the logic
1. Linear scan is O(n). Finding the rotation point first and then binary searching the correct side works: O(log n), two passes.
2. **One pass:** pick `mid`. At least one of `[lo, mid]` and `[mid, hi]` is sorted, because the single "drop" in the array lies in at most one of them.
3. Decide which: if `array[lo] <= array[mid]`, the left half is sorted; otherwise the right half is.
4. In the sorted half you can check range membership exactly (`array[lo] <= target < array[mid]`). If the target is inside, go there; otherwise go to the other half.
5. `<=` in `array[lo] <= array[mid]` matters when `lo == mid` (two elements left).

## Complexity
- Time: O(log n).
- Space: O(1) iterative.

## Interview notes
- LeetCode #33. With duplicates (#81), `array[lo] == array[mid] == array[hi]` gives no information; shrink both ends by one, which makes the worst case O(n). Mention it.
- Related: find the minimum in a rotated array (#153), the rotation count.
