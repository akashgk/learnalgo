# Selection Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Repeated minimum selection

## Problem
Sort an array of integers in ascending order using Selection Sort.

## Building up the logic
1. Invariant: `array[0..start-1]` holds the smallest `start` elements, in order.
2. Scan the unsorted suffix for its minimum; swap it into position `start`.
3. Repeat until one element remains.

## Complexity
- Time: O(n^2) in every case. It always scans the full suffix, even when sorted.
- Space: O(1).
- Swaps: at most n - 1. That is its only advantage: useful when writes are expensive.
- **Not stable:** the long-distance swap can jump an element past an equal one. Example: `[5a, 5b, 2]` -> swap 5a with 2 -> `[2, 5b, 5a]`.

## Interview notes
- Heap Sort is selection sort with a heap to find the minimum (or maximum) in O(log n) instead of O(n). Knowing that link helps you remember both.
