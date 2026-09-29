# Binary Tree Diameter

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Bottom-up DFS returning multiple values

## Problem
The diameter of a binary tree is the length (number of edges) of the longest path between any two nodes. The path does not have to pass through the root. Return the diameter.

## Building up the logic
1. Every path has a single highest node where it "bends". At that node, the path's length is `height(left) + height(right)` (heights measured in nodes, which equals edges from the bend down).
2. So the diameter is the maximum over all nodes of `height(left) + height(right)`.
3. Naive: compute heights separately at every node: O(n^2) on skewed trees.
4. **Bottom-up:** one post-order pass where each call returns both its subtree's best diameter and its height. The parent combines them in O(1).
5. Returning a Dart record `({int diameter, int height})` keeps it clean without a mutable global. A global `best` variable updated during a height-only DFS is equally valid and common.

## Complexity
- Time: O(n).
- Space: O(h) recursion.

## Interview notes
- The "return several values from each subtree" technique is the key to many hard tree problems: Max Path Sum In Binary Tree, Height Balanced Binary Tree, Largest BST in a Binary Tree (LeetCode #333), House Robber III (#337).
- Clarify "length" as edges vs nodes; it changes the answer by one.
- LeetCode #543.
