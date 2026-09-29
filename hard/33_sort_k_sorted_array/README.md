# Sort K-Sorted Array

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Sliding window min-heap

## Problem
An array is k-sorted: every element is at most k positions away from where it belongs in sorted order. Sort it in place, faster than a general O(n log n) sort when k is small.

## Building up the logic
1. General sort: O(n log n), ignores k.
2. Insertion sort: O(n * k), because each element shifts at most k places. Decent for tiny k.
3. **Key observation:** the element that belongs at position 0 must be among the first `k + 1` elements. After placing it, the element for position 1 must be among the next window, and so on.
4. Keep a min-heap of the current `k + 1` candidates. Pop the minimum into the next output slot, push the next input element. Writing into `array` behind the read position is safe because the write index never overtakes the read index.

## Complexity
- Time: O(n log k).
- Space: O(k).

## Interview notes
- Same heap-of-candidates idea as Merge Sorted Arrays (k-way merge) and "k closest elements". Explain why the window is `k + 1`, not `k`.
