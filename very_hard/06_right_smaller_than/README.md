# Right Smaller Than

**Difficulty:** Very Hard | **Category:** Binary Search Trees | **Pattern:** Augmented BST or merge sort counting

## Problem
For each element of an integer array, count how many elements to its right are strictly smaller. Return the counts.

```
[8, 5, 11, -1, 3, 4, 2]  ->  [5, 4, 4, 0, 1, 1, 0]
```

## Building up the logic
1. Brute force: O(n^2).
2. **AlgoExpert's intended BST approach:** insert elements from **right to left** into a BST where each node stores the size of its left subtree. While inserting value `v`, every time you go right you pass a node smaller than `v` plus its whole left subtree: add `leftSize + 1` (or just `leftSize` for an equal node). The total at insertion is the answer for that index. Average O(n log n), but **O(n^2) worst case** for sorted input because the BST is unbalanced.
3. **Merge sort approach (this code, guaranteed O(n log n)):** sort indices by value with merge sort. When merging, the right half contains elements originally to the right of every left-half element. When a left element is placed, the `j` right elements already placed are smaller than it: add `j` to its count. Using `<=` when comparing sends equal values left first, so equal elements are not counted (strictly smaller).
4. A Fenwick tree (binary indexed tree) over compressed values, processed right to left, is a third O(n log n) solution and very short to write once you know BITs.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(n) |
| Augmented BST | O(n log n) avg, O(n^2) worst | O(n) |
| Merge sort / Fenwick tree | O(n log n) | O(n) |

## Interview notes
- LeetCode #315 (Count of Smaller Numbers After Self). Same merge-sort counting idea as Count Inversions (the inversion count is the sum of this output).
