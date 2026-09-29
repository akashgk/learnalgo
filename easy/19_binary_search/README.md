# Binary Search

**Difficulty:** Easy | **Category:** Searching | **Pattern:** Binary search

## Problem
Given a sorted array of integers and a target, return the index of the target or -1 if it is absent.

## Building up the logic
1. Linear scan is O(n) and ignores sortedness.
2. Compare with the middle element. If it is too small, the target (if present) must be to the right; discard the left half. Each comparison halves the search space, so O(log n).
3. Decide on an **invariant** and stick to it. Here: "if the target exists, it is in `[lo, hi]` (inclusive)". That dictates `while (lo <= hi)`, `lo = mid + 1`, `hi = mid - 1`. Most binary search bugs come from mixing inclusive and half-open conventions.
4. Compute `mid` as `lo + (hi - lo) ~/ 2`. In Java/C++ `(lo + hi) / 2` can overflow; mention it even though Dart's 64-bit ints make it irrelevant here.

## Complexity
- Time: O(log n).
- Space: O(1) iterative; O(log n) recursive.

## Interview notes
- Variants you must be able to write from this template: first/last occurrence (Search For Range), insertion point (lower bound), rotated array (Shifted Binary Search), search on the answer space ("minimum capacity to ship packages", LeetCode #1011).
- With duplicates (like `45, 45` above), plain binary search returns *an* index, not necessarily the first.
