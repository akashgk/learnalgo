# Node Depths

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** DFS/BFS with depth

## Problem
The depth of a node is its distance (number of edges) from the root. Given a binary tree, return the sum of the depths of all its nodes.

## Building up the logic
1. A node's depth is its parent's depth plus one. So depth is top-down state, passed to children.
2. Recursively: `f(node, d) = d + f(left, d+1) + f(right, d+1)`, with `f(null, _) = 0`.
3. Iteratively: push `(node, depth)` pairs on a stack (DFS) or queue (BFS). Order does not matter because you only sum.
4. Know both. Interviewers sometimes ask for the iterative form to avoid stack overflow on deep trees.

## Complexity
- Time: O(n).
- Space: O(h) for the stack, where h is the height (O(log n) balanced, O(n) skewed). A BFS queue would be O(w), the maximum width.

## Edge cases
- Root alone: 0.

## Interview notes
- Dart 3 idioms used: records `(BinaryTree, int)` as lightweight tuples, record destructuring `final (node, depth) = ...`, and `if (x case final y?)` for null-check-and-bind.
- The very hard follow-up is **All Kinds Of Node Depths** (sum of node depths when every node is treated as a root), solved in O(n) with a bottom-up pass.
