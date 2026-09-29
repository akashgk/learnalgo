# Validate Three Nodes

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** BST search between nodes

## Problem
Given three distinct nodes of a BST, return whether `nodeTwo` lies strictly between the other two on a root-to-leaf path: either `nodeOne` is an ancestor of `nodeTwo` and `nodeTwo` is an ancestor of `nodeThree`, or the same with `nodeOne` and `nodeThree` swapped. Nodes have no parent pointers.

## Building up the logic
1. In a BST, "is `x` a descendant of `a`?" is answered by searching for `x.value` starting at `a`. O(h).
2. `nodeTwo` must have an ancestor among the other two. Check both possibilities:
   - if `nodeOne` is an ancestor of `nodeTwo`, the answer is whether `nodeTwo` is an ancestor of `nodeThree`;
   - else if `nodeThree` is an ancestor of `nodeTwo`, check whether `nodeTwo` is an ancestor of `nodeOne`;
   - otherwise false.
3. Compare nodes by identity (duplicates are allowed in the BST).

## Optimization (AlgoExpert's O(d) version)
Search from `nodeOne` and `nodeThree` toward `nodeTwo` **simultaneously**, one step each. Whichever finds it first is the candidate ancestor, and the search stops as soon as either succeeds or both fail. This bounds work by the distance between the nodes (d) instead of full heights, which matters when the three nodes are close but deep.

## Complexity
- Time: O(h) (this version), O(d) with the simultaneous search.
- Space: O(1) iterative.

## Interview notes
- Clarify whether "ancestor" includes the node itself. Here the three nodes are distinct, so the strict version is used.
