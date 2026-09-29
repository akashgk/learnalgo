# Invert Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Visit every node and swap children

## Problem
Invert (mirror) a binary tree in place: every left subtree becomes the right subtree and vice versa.

## Building up the logic
1. Mirroring the whole tree = mirroring each node locally. Swap each node's `left` and `right` pointers.
2. Order does not matter: any traversal that visits every node once works (pre-order, post-order, BFS).
3. Recursive: `invert(t) = swap(invert(t.left), invert(t.right))`.
4. Iterative BFS avoids recursion depth issues on deep trees.

## Complexity
- Time: O(n).
- Space: recursive O(h); BFS O(w) where w is the widest level (up to about n/2 for a complete tree).

## Interview notes
- Famous because of a tweet by the author of Homebrew about failing it at Google. It is a warm-up; answer in two minutes and move on to follow-ups: "Is it symmetric?" (Symmetrical Tree), "Are two trees mirror images?"
- LeetCode #226.
