# Smallest Difference

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort both + two pointers

## Problem
Given two non-empty integer arrays, find the pair (one number from each) whose absolute difference is closest to zero. Return `[fromFirst, fromSecond]`. Assume a unique best pair.

## Building up the logic
1. Brute force: all pairs, O(n * m).
2. Sort both arrays. Put a pointer at the start of each.
3. At `(x, y)` with `x < y`: advancing `j` makes `y` bigger and the gap bigger, so the only useful move is advancing `i`. Symmetric when `x > y`. Each step discards an element that cannot do better with any remaining partner.
4. If `x == y`, the difference is 0: return immediately.

## Complexity
- Time: O(n log n + m log m) for sorting; the scan is O(n + m).
- Space: O(1) extra with in-place sorting (O(n + m) here because of copies).

## Alternative
Sort only the smaller array and binary search each element of the larger one: O((n + m) log(min(n, m))). Useful if one array is tiny.

## Interview notes
- This is the "merge step" of merge sort used as a search. The same walk solves "intersection of two sorted arrays" and "k-th smallest across two arrays" (naive version).
- Use a safe initial "infinity". `double.maxFinite.toInt()` clamps to the max 64-bit int on native Dart.
