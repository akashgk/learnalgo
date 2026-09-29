# Validate BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Top-down bounds

## Problem
Given a binary tree, return whether it is a valid BST: every node is strictly greater than all values in its left subtree and less than or equal to all values in its right subtree.

## Building up the logic
1. **The trap:** checking only `left.value < node.value <= right.value` at each node is wrong. It misses a grandchild violating a grandparent. Example: 11 as the right child of 5, where 5 is the left child of 10. Locally fine, globally invalid. Interviewers use this exact example to see if you fall for it.
2. Each node must lie within an interval inherited from **all** its ancestors. Going left tightens the upper bound to the parent's value; going right tightens the lower bound.
3. Pass `(min, max)` down: root has `(-inf, +inf)`; left child gets `(min, parent)`; right child gets `(parent, max)`.
4. Using nullable bounds (`int?`) avoids sentinel problems when the tree contains the minimum/maximum integer.

## Alternative
An in-order traversal of a BST is sorted. Traverse in-order keeping the previous value; fail if `current < previous` (or `<=` depending on the duplicate rule). Also O(n) / O(h). This version is harder to get right with the "duplicates go right" rule, because in-order cannot tell whether an equal value came from the left or the right.

## Complexity
- Time: O(n).
- Space: O(h) recursion (O(log n) balanced, O(n) skewed).

## Interview notes
- LeetCode #98. Their definition forbids duplicates entirely, so both bounds are strict. Clarify the duplicate rule first.
