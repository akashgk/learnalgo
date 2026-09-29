# Branch Sums

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** DFS with accumulated state

## Problem
Given a binary tree, return a list of its branch sums ordered from the leftmost branch to the rightmost. A branch sum is the sum of all values on a root-to-leaf path.

## Building up the logic
1. A branch ends at a **leaf** (no children), not at any node with a missing child. A node with only one child is not the end of a branch. This distinction is the most common bug.
2. Each node needs to know the sum of everything above it. Pass that down as a parameter ("top-down state").
3. Visiting left before right gives the required left-to-right order. That is just preorder DFS.
4. Base cases: null node returns nothing; leaf appends `running + value`.

## Complexity
- Time: O(n), each node visited once.
- Space: O(n). The output holds one entry per leaf (up to about n/2), and the recursion stack is O(h), which is O(n) for a skewed tree and O(log n) for a balanced one.

## Edge cases
- Single node: one branch equal to the root value.
- Skewed tree: one branch, recursion depth n.

## Interview notes
- Top-down (pass state to children) vs bottom-up (return state to the parent) is the most important binary-tree distinction. This problem is top-down. Diameter and Height Balanced are bottom-up.
- Related: LeetCode #112 (Path Sum), #113 (Path Sum II), #129 (Sum Root to Leaf Numbers).
