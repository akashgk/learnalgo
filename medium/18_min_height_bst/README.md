# Min Height BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Divide and conquer

## Problem
Given a sorted array of distinct integers, build a BST containing all of them with the minimum possible height, and return its root.

## Building up the logic
1. Inserting values in sorted order gives a linked list (height n). Bad.
2. For minimum height, each node's subtrees should hold as close to half the remaining values as possible.
3. Choosing the **middle** of the sorted range as the root puts half the values left (all smaller) and half right (all larger), satisfying the BST property automatically.
4. Recurse on the left half and right half. This is binary search turned into construction.

## Complexity
- Time: O(n): each element becomes one node, created in O(1) (the naive approach of calling `insert` repeatedly costs O(n log n)).
- Space: O(n) for the tree; O(log n) recursion depth.

## Interview notes
- Resulting height: `ceil(log2(n + 1))`.
- LeetCode #108. Follow-up: build from a sorted **linked list** (#109) in O(n) by simulating in-order traversal (build left subtree, consume the current list node, build right subtree).
