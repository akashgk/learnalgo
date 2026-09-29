# Quick Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Divide and conquer via partitioning

## Problem
Sort an integer array in ascending order using Quick Sort.

## Building up the logic
1. Choose a pivot. **Partition** so everything smaller is left of it and everything larger is right. The pivot is then in its final position.
2. Recursively sort the two sides. No merge step is needed (unlike merge sort): the work is done during partitioning.
3. Partition used here (first element as pivot, two pointers):
   - `left` scans right for an element `> pivot`, `right` scans left for an element `< pivot`; when both are stuck, swap them.
   - When the pointers cross, swap the pivot into position `right`.
4. **Stack depth:** recursing into the smaller side and looping on the larger bounds the recursion depth at O(log n) even in bad cases. Mentioning this is a sign of depth.
5. **Worst case:** a consistently extreme pivot (already sorted input with a first-element pivot) gives O(n^2). Fixes: random pivot, median-of-three, or introsort (switch to heap sort when recursion gets too deep, as C++ `std::sort` does).

## Complexity
| Case | Time |
|---|---|
| Best / average | O(n log n) |
| Worst | O(n^2) |

Space: O(log n) stack (with the smaller-side trick). **Not stable.** In place.

## Interview notes
- Why is quicksort often faster than merge sort in practice despite the worse worst case? In-place, cache-friendly sequential access, small constants.
- Know Lomuto (used in Quickselect here) vs Hoare partition schemes: Hoare does fewer swaps.
