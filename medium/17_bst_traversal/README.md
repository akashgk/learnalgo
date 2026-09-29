# BST Traversal

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** DFS orders

## Problem
Implement in-order, pre-order, and post-order traversals of a BST, each appending values to an output list.

## Building up the logic
The three orders differ only in **when the node itself is visited** relative to its subtrees:

| Order | Sequence | Typical use |
|---|---|---|
| Pre-order | node, left, right | Copy/serialize a tree; reconstruct a BST (Reconstruct BST) |
| In-order | left, node, right | Produces **sorted** output for a BST; validate BST; k-th smallest |
| Post-order | left, right, node | Compute from children upward: heights, deletion, expression evaluation |

## Complexity
- Time: O(n) each.
- Space: O(n) for the output; O(h) recursion.

## Interview notes
- Be ready to write each traversal **iteratively** with an explicit stack (Iterative In-order Traversal in the very hard section does it with O(1) extra space using parent pointers). Morris traversal gives O(1) extra space without parent pointers by temporarily threading the tree.
- Level-order (BFS) is the fourth traversal; it uses a queue.
