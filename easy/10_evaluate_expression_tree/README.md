# Evaluate Expression Tree

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** Postorder (bottom-up) recursion

## Problem
A binary expression tree has non-negative integers at the leaves and operators at internal nodes, encoded as negative numbers: `-1` addition, `-2` subtraction, `-3` division (rounded toward zero), `-4` multiplication. Every operator node has exactly two children. Evaluate the tree.

## Building up the logic
1. An operator can only be applied once both operands are known. So children must be evaluated before their parent: that is **postorder**, the canonical bottom-up traversal.
2. Base case: a non-negative value is a leaf; return it.
3. Recursive case: evaluate left, evaluate right, combine.
4. Watch integer division semantics. "Round toward zero" means `-7 / 2 = -3`, not `-4`. Dart's `~/` truncates toward zero (like Java/C). Python's `//` floors, which is a known trap.

## Complexity
- Time: O(n).
- Space: O(h) recursion depth.

## Edge cases
- Single leaf.
- Negative intermediate result in a division.

## Interview notes
- A Dart 3 `switch` expression maps operator codes to results cleanly and forces you to handle the default case.
- Related: Reverse Polish Notation (the postorder serialization of this tree, evaluated with a stack), LeetCode #150.
