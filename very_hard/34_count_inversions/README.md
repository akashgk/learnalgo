# Count Inversions

**Difficulty:** Very Hard | **Category:** Sorting | **Pattern:** Merge sort with counting

## Problem
An inversion is a pair of indices `i < j` with `array[i] > array[j]`. Return the number of inversions, which measures how far the array is from sorted.

```
[2, 3, 3, 1, 9, 5, 6]  ->  5   ((2,1), (3,1), (3,1), (9,5), (9,6))
```

## Building up the logic
1. Brute force over pairs: O(n^2).
2. Divide and conquer: inversions = inversions inside the left half + inside the right half + **cross** inversions (left element > right element).
3. If both halves are **sorted**, cross inversions are easy to count during the merge: when a right element `a[j]` is placed before the remaining left elements, it is smaller than all of them, contributing `mid - i` inversions at once.
4. Merging also sorts the range, which is exactly what the parent level needs. So counting piggybacks on merge sort for free.
5. Use `<=` so equal elements are not counted (not an inversion).

## Complexity
- Time: O(n log n).
- Space: O(n).

## Interview notes
- Classic in CLRS and Kleinberg-Tardos; used to measure ranking similarity (Kendall tau distance). LeetCode #493 (Reverse Pairs, `a[i] > 2 * a[j]`) needs a separate counting pass before each merge.
- Alternative: Fenwick tree over compressed values, scanning right to left. Same complexity.
