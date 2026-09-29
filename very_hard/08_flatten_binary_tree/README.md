# Flatten Binary Tree

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Bottom-up recursion returning list endpoints

## Problem
Flatten a binary tree **in place** into a doubly linked list ordered by in-order traversal: each node's `left` points to the previous node and `right` to the next. Return the leftmost node (the head).

## Building up the logic
1. **Simple version:** collect nodes by in-order traversal into an array, then link neighbors. O(n) time, O(n) extra space.
2. **In place:** a subtree's flattened list runs from its leftmost to its rightmost node. If each recursive call returns those two endpoints, the parent only needs to splice:
   - `leftSubtree.last <-> node <-> rightSubtree.first`
   - its own endpoints are `leftSubtree.first` (or itself) and `rightSubtree.last` (or itself).
3. Recurse into children **before** overwriting their pointers. Save them or read them first, as this code does via the `case final l?` binding.

## Complexity
- Time: O(n).
- Space: O(h) recursion.

## Interview notes
- LeetCode #426 (Convert BST to Sorted Doubly Linked List, often circular). Different from #114 (Flatten Binary Tree to Linked List), which uses **pre-order** and only `right` pointers; read which one you are asked.
- Dart note: returning a record `(first, last)` makes the endpoints explicit with no helper class.
