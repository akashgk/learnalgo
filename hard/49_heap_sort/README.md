# Heap Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Max-heap + repeated extraction

## Problem
Sort an integer array in ascending order using Heap Sort.

## Building up the logic
1. Selection sort repeatedly finds the maximum of the unsorted part in O(n). A **max-heap** finds it in O(1) and restores itself in O(log n). Heap sort is selection sort with a heap.
2. **Build the heap in place** (O(n)): sift down every non-leaf index from the last parent back to 0 (see Min Heap Construction for why this is linear).
3. **Extract:** swap the root (max) with the last element of the heap region; the max is now in its final sorted place. Shrink the heap region by one and sift down the new root.
4. Repeat until the heap region has one element.

## Complexity
- Time: O(n log n) best, average, and worst. No bad inputs, unlike quicksort.
- Space: O(1): fully in place.
- **Not stable.**

## Interview notes
- Why is heap sort less used than quicksort despite the guaranteed bound? Poor cache locality (jumps between parent and children) and larger constants. It is used as the fallback in introsort.
- Sorting algorithm cheat sheet is in the repo root README.
