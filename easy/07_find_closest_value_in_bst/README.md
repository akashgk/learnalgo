# Find Closest Value In BST

**Difficulty:** Easy | **Category:** Binary Search Trees | **Pattern:** BST descent

## Problem
Given the root of a Binary Search Tree and a target integer, return the value in the BST that is closest to the target. Assume exactly one closest value.

BST property: every node's value is strictly greater than all values in its left subtree and less than or equal to all values in its right subtree.

## Building up the logic
1. Brute force: visit every node, track the closest. O(n). Works for any binary tree, so it ignores the BST property.
2. At a node with value `v`: if `target < v`, every node in the right subtree is `>= v`, so it is even farther from the target than `v` is. The right subtree can be discarded. Symmetrically for `target > v`.
3. So walk a single root-to-leaf path, updating the best candidate at each step. This is binary search on a tree.
4. Stop early on an exact match (difference 0 cannot be beaten).
5. Prefer the iterative version: same logic, but O(1) space instead of O(depth) call stack.

## Complexity
| | Time | Space |
|---|---|---|
| Balanced BST | O(log n) | O(1) iterative, O(log n) recursive |
| Degenerate (linked-list shaped) BST | O(n) | O(1) iterative, O(n) recursive |

## Edge cases
- Target smaller than the minimum or larger than the maximum.
- Single-node tree.

## Interview notes
- Always state both average and worst-case complexity for BSTs; interviewers check whether you know an unbalanced BST degrades to O(n).
- Related: LeetCode #270 (Closest BST Value), #272 (k closest values, use inorder + sliding window or two stacks).
