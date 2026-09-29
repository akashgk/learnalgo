# Compare Leaf Traversal

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Lockstep lazy traversal (generators / explicit stacks)

## Problem
Given two binary trees, return whether their leaves, read from left to right, form the same sequence. The trees' shapes may differ.

## Building up the logic
1. Collect both leaf sequences into lists and compare: O(n + m) time, O(n + m) space. Fine, but it cannot stop early, and it stores every leaf.
2. **Lockstep:** produce leaves **on demand** from each tree and compare pairwise, stopping at the first mismatch. Each tree only needs a DFS stack of size O(h).
3. In Dart, a `sync*` generator expresses "produce the next leaf when asked" directly; the iterators advance in lockstep. In Java you would write an iterator class; in Python, a generator.
4. After the loop, both iterators must be exhausted at the same time (one tree may have extra leaves).
5. AlgoExpert's alternative O(h) approach links leaves into a linked list during traversal (reusing `right` pointers), which also gives O(h) space but mutates the trees.

## Complexity
- Time: O(n + m) worst case, with early exit on mismatch.
- Space: O(h1 + h2).

## Interview notes
- LeetCode #872 (Leaf-Similar Trees). The "compare two lazy streams" technique also solves "are two BSTs' in-order sequences equal" and the classic "same fringe" problem from Lisp folklore.
