# Iterative In-order Traversal

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Stackless traversal using parent pointers

## Problem
Given a binary tree whose nodes have `parent` pointers, perform an in-order traversal, calling a callback on each node, **iteratively with O(1) extra space** (no recursion, no stack).

## Building up the logic
1. A recursive or stack-based traversal uses O(h) memory to remember where to return. Parent pointers provide that information for free.
2. The only missing piece: when you arrive at a node, **where did you come from?** Keep a `previous` pointer.
   - From the **parent** (or starting at the root): go down left if there is a left child. If not, the node's left subtree is (trivially) done: visit it, then go right, or up if there is no right child.
   - From the **left child**: left subtree done; visit, then go right or up.
   - From the **right child**: both subtrees done; go up.
3. The traversal ends when you move up from the root (current becomes null).

## Complexity
- Time: O(n): each edge is traversed twice (down and up).
- Space: O(1).

## Interview notes
- Without parent pointers, **Morris traversal** achieves O(1) space by temporarily threading each in-order predecessor's right pointer to the current node, then restoring it. Worth knowing; LeetCode #94 follow-up.
- The explicit-stack version (push all lefts, pop, visit, go right) is the one you should be able to write in your sleep; see Find Kth Largest Value In BST.
