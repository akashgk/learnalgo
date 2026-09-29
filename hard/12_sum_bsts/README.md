# Sum BSTs

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** Bottom-up DFS returning subtree summaries

## Problem
Given a binary tree, find every subtree that is a valid BST with at least 3 nodes and return the sum of their sizes. If a BST subtree is contained within a larger BST subtree, only the larger one is counted (so no node is counted twice). Duplicates go to the right.

> Definition note: this matches the behavior of AlgoExpert's reference solution as I recall it (a counted BST replaces its children's totals). The problem statement is paywalled, so verify the exact wording if you practice on the site. The variant "count every BST subtree, even nested ones" is a one-line change: `total = l.total + r.total + (isBst && size >= 3 ? size : 0)`.

## Building up the logic
1. Checking "is this subtree a BST?" separately at every node is O(n^2).
2. Bottom-up: to decide whether the subtree at `t` is a BST you only need, from each child: is it a BST, its min, its max, and its size. Then `t` is a BST iff both children are BSTs and `leftMax < t.value <= rightMin`.
3. Also carry the running answer (`total`) for each subtree. If `t`'s subtree is a counted BST, its total is just its size; otherwise it is the sum of the children's totals.
4. Null children return neutral values: `isBst = true`, `min = +inf`, `max = -inf`, size 0, so comparisons pass automatically.

## Complexity
- Time: O(n).
- Space: O(h).

## Interview notes
- Same template as LeetCode #333 (Largest BST Subtree) and #1373 (Maximum Sum BST in Binary Tree). Returning a record/tuple of several values from each subtree is the key skill.
