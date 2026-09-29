# Merge Sort

**Difficulty:** Very Hard (on AlgoExpert, because of the space-efficient version) | **Category:** Sorting | **Pattern:** Divide and conquer

## Problem
Sort an integer array ascending using Merge Sort.

## Building up the logic
1. **Divide:** split the array in half, sort each half recursively.
2. **Conquer:** merge two sorted halves into one sorted range with two pointers (the same merge as Merge Linked Lists).
3. **Naive version:** slicing creates new arrays at every level: O(n log n) extra allocations, O(n log n) total memory churn (O(n) live at any time, but lots of copying).
4. **Single auxiliary buffer:** allocate one copy of the array up front. At each level, the recursive calls sort the halves **into** the other buffer, and the current call merges from it back into its target. Swapping the roles of `main` and `aux` at every level avoids copying back and forth.
5. Using `<=` when elements are equal takes from the left half first, which makes merge sort **stable**.

## Complexity
- Time: O(n log n) best, average, and worst: log n levels, O(n) merging per level.
- Space: O(n) auxiliary + O(log n) recursion.
- Stable. Not in place (in-place merging exists but is complex and slower).

## Interview notes
- Why choose merge sort? Guaranteed O(n log n), stability (Java's `Arrays.sort` for objects and Python's TimSort are merge-based), linked lists (no random access needed, O(1) extra space for merging nodes), and external sorting.
- The merge step is reused for counting inversions (Count Inversions) and Right Smaller Than.
