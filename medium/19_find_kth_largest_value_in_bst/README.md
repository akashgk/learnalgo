# Find Kth Largest Value In BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Reverse in-order with early exit

## Problem
Given a BST and a positive integer k (at most the number of nodes), return the k-th largest value. Duplicates count separately.

## Building up the logic
1. Simple: in-order traversal into a list (sorted ascending), return `list[n - k]`. O(n) time and space. Good baseline.
2. You only need the top k. In-order gives ascending order; **reverse in-order** (right, node, left) gives descending order.
3. Count visits and stop at the k-th. You then only touch the path to the maximum plus k nodes.
4. The iterative stack version makes early exit trivial (no need to unwind recursion with flags).

## Complexity
- Time: O(h + k): h to descend to the maximum, then k visits.
- Space: O(h) for the stack.

## Interview notes
- Follow-up (LeetCode #230): "the BST is modified often and k-th queries are frequent." Store subtree sizes in each node; then k-th is O(h) by comparing k with the right subtree size, and inserts/deletes update sizes along the path.
