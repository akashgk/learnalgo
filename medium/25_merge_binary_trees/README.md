# Merge Binary Trees

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Simultaneous traversal of two trees

## Problem
Given two binary trees, merge them: where both trees have a node at the same position, the merged node's value is the sum; where only one has a node, use that node (and its whole subtree). Return the merged tree.

## Building up the logic
1. Traverse both trees in lockstep, position by position.
2. Base cases carry the logic: if one side is null, the result at this position is simply the other side (whole subtree reused, no need to copy it).
3. Otherwise sum the values into `tree1` and recurse on both children pairs.
4. Mutating `tree1` avoids allocation. If inputs must not be modified, create new nodes instead; say which you are doing.

## Complexity
- Time: O(min(n1, n2)): recursion only continues where both trees have nodes.
- Space: O(min(h1, h2)) recursion.

## Interview notes
- Iterative version: a stack of `(node1, node2)` pairs; when `node1.left` is null, attach `node2.left` directly.
- LeetCode #617.
