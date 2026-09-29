# Lowest Common Manager

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Post-order counting (LCA without parent pointers)

## Problem
An org chart is an n-ary tree: each manager has a list of direct reports. Given the top manager and two reports (both in the tree), return their lowest common manager: the deepest manager that has both reports in its hierarchy. A manager counts as being in its own hierarchy.

## Building up the logic
1. Unlike Youngest Common Ancestor, there are no parent pointers, so you cannot climb up. Information must flow **bottom-up**.
2. Each subtree returns how many of the two target reports it contains (0, 1, or 2).
3. A node's count = sum of its children's counts + 1 for each target it is itself.
4. The **first** node (in post-order, i.e. the deepest) whose count reaches 2 is the answer; every ancestor above it also has count 2, so record only the first.
5. Early exit: once found, stop exploring remaining subtrees.

## Complexity
- Time: O(n).
- Space: O(d), the depth of the org chart (recursion).

## Interview notes
- This is LCA in a general tree, LeetCode #236 (binary tree version, same idea: return the node if found in both subtrees).
- Contrast: BST LCA (#235) walks down using values in O(h); parent-pointer LCA (Youngest Common Ancestor) walks up.
