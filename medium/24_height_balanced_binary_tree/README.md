# Height Balanced Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Bottom-up DFS with sentinel

## Problem
A binary tree is height balanced if, for **every** node, the heights of its left and right subtrees differ by at most 1. Return whether the given tree is height balanced.

## Building up the logic
1. Naive: for each node, compute both subtree heights with a separate traversal and compare. O(n^2) on skewed trees, O(n log n) balanced.
2. Heights are computed bottom-up anyway, so check balance at the same time. Each call returns its height.
3. Encode "unbalanced somewhere below" as a sentinel (-1). A record `(isBalanced, height)` is equally good and more explicit; the sentinel is shorter and allows early exit.
4. Early exit: if the left subtree is unbalanced, skip the right subtree.

## Complexity
- Time: O(n).
- Space: O(h).

## Interview notes
- Common mistake: checking balance only at the root. The definition is "for every node".
- LeetCode #110. This is the same bottom-up template as Binary Tree Diameter.
