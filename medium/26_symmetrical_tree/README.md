# Symmetrical Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Paired traversal (mirror comparison)

## Problem
Return whether a binary tree is symmetric around its center: its left subtree is the mirror image of its right subtree, in both structure and values.

## Building up the logic
1. Two trees `a` and `b` are mirrors if their roots are equal, `a.left` mirrors `b.right` (outer pair) and `a.right` mirrors `b.left` (inner pair).
2. Start with `(root.left, root.right)`.
3. Null handling: both null is fine; exactly one null is a mismatch. `a == b` when one is null captures both cases in one line.
4. Iterative: a queue/stack of pairs, pushing `(a.left, b.right)` and `(a.right, b.left)`.

## Complexity
- Time: O(n).
- Space: O(h) recursion, or O(w) with a BFS queue.

## Interview notes
- Wrong approach to avoid: comparing the in-order traversal to its reverse. Different structures can produce identical sequences, so it gives false positives unless you also record nulls.
- LeetCode #101.
