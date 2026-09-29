# Find Successor

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Structural case analysis with parent pointers

## Problem
Given a binary tree whose nodes have `parent` pointers, and a node in it, return that node's successor in in-order traversal (the node visited right after it), or null if it is the last.

## Building up the logic
1. Brute force: in-order traverse the whole tree into a list, find the node, return the next one. O(n) time and space. Works for any tree and does not need parent pointers.
2. Use the definition of in-order (left, node, right) to reason locally:
   - **Node has a right subtree:** after the node, in-order visits its right subtree, starting with that subtree's leftmost node.
   - **No right subtree:** the node's subtree is finished. Climb up. While you are coming up from a **right** child, that parent's subtree is also finished. The first time you come up from a **left** child, that parent is the next to be visited.
   - If you reach the root without that happening, the node was the last in in-order: return null.
3. Draw both cases on a small tree before coding. Interviewers look for the case split.

## Complexity
- Time: O(h).
- Space: O(1).

## Interview notes
- In a BST without parent pointers (LeetCode #285), search from the root: whenever you go left, record the current node as a candidate successor. O(h).
- LeetCode #510 is exactly this problem.
