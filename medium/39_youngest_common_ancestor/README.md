# Youngest Common Ancestor

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Lowest common ancestor with parent pointers

## Problem
Each node in an ancestral tree has a pointer to its direct ancestor (parent). Given the top ancestor and two descendants, return their youngest (deepest) common ancestor. A node counts as its own ancestor.

## Building up the logic
1. **Hash set approach:** walk from `one` to the top, storing every ancestor. Then walk from `two` upward; the first node found in the set is the answer. O(d) time, O(d) space.
2. **O(1) space:** if both nodes were at the same depth, stepping both up one at a time would make them meet exactly at the youngest common ancestor.
3. So first compute both depths, move the deeper node up by the difference, then climb in lockstep until they are the same node.
4. Compare node identity, not names (names might repeat in other variants).

## Complexity
- Time: O(d), where d is the depth of the deeper descendant.
- Space: O(1).

## Interview notes
- The same idea as "intersection of two linked lists" (LeetCode #160): parent pointers form two linked lists that merge. The elegant two-pointer trick there (switch heads when reaching the end) also works here.
- Without parent pointers, LCA in a binary tree is a recursive post-order (#236); in a BST, walk down from the root (#235); for many queries, binary lifting gives O(log n) per query after O(n log n) preprocessing.
