# Split Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Subtree sums (post-order)

## Problem
Given a binary tree of integers (values may be negative), determine whether removing a single edge can split it into two trees with equal sums. If so return that sum, otherwise return 0.

## Building up the logic
1. Removing an edge detaches a subtree. The detached part is a subtree rooted at some non-root node; the rest has sum `total - subtreeSum`.
2. Equal halves means `subtreeSum == total / 2`. So: if `total` is odd, answer 0 immediately.
3. Compute every subtree sum in one post-order pass and check whether any **non-root** subtree hits `total / 2`.
4. Exclude the root: the root's subtree is the whole tree, which is not a split. This matters when `total == 0` (the root would trivially equal `0 / 2`).

## Complexity
- Time: O(n) (two passes).
- Space: O(h).

## Edge cases
- Negative values mean you cannot prune early when a partial sum exceeds half.
- Total 0 with a single node: no edge to remove, answer 0.
- Ambiguity: when total is 0 and a valid split exists, the answer "0" is indistinguishable from "no split". That is a flaw in the problem's return format; mention it.

## Interview notes
- LeetCode #663 (Equal Tree Partition), which returns a boolean and avoids the ambiguity.
