# Reconstruct BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Pre-order consumption with bounds

## Problem
Given the pre-order traversal values of a BST (duplicates go to the right), rebuild the BST and return its root.

## Building up the logic
1. The first value is the root. The following values smaller than the root form the left subtree; the rest form the right subtree.
2. **Naive O(n^2):** for each root, scan forward to find where the right subtree starts, and recurse on the two slices. A skewed tree makes each scan O(n).
3. **Insight:** pre-order visits a node, then its entire left subtree, then its entire right subtree. If you read values left to right with a shared index, each value belongs to the **current** subtree if and only if it fits that subtree's valid range. That is the same bound idea as Validate BST.
4. `build(lower, upper)`: if the next value is outside `[lower, upper)`, this subtree is empty; return null without consuming it. Otherwise consume it, build left with `(lower, value)`, build right with `(value, upper)`.
5. Every value is consumed exactly once, so it is linear.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Slice at first larger value | O(n^2) worst, O(n log n) balanced | O(n) |
| Shared index + bounds | O(n) | O(n) (tree) and O(h) stack |

## Interview notes
- LeetCode #1008. A monotonic-stack O(n) construction also exists: push nodes; for each new value pop while the stack top is smaller, attach as right child of the last popped, else as left child of the top.
- A BST is uniquely determined by its pre-order (or post-order) alone. A general binary tree needs two traversals (in-order + pre-order), LeetCode #105.
