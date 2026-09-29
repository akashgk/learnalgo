# Insertion Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Sorted prefix + insertion

## Problem
Sort an array of integers in ascending order using Insertion Sort.

## Building up the logic
1. Invariant: `array[0..i-1]` is sorted.
2. Take `array[i]`, and shift every larger element in the prefix one step right until you find its spot. Drop it there.
3. Shifting (one write per step) is cheaper than swapping (three writes per step).

## Complexity
- Best: O(n) when the array is already sorted (inner loop never runs).
- Average/worst: O(n^2). More precisely O(n + inversions), which is why it is excellent on nearly-sorted data.
- Space: O(1). Stable.

## Interview notes
- Real-world sorts (TimSort in Python/Java, introsort variants in C++, Dart's own `List.sort` for short ranges) switch to insertion sort for small subarrays because of low constant factors.
- The "O(n + number of inversions)" fact links to Count Inversions and Sort K-Sorted Array.
