# Right Sibling Tree

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** In-place pointer rewiring with careful ordering

## Problem
Transform a binary tree in place so that every node's `right` pointer points to its **right sibling** instead of its right child. Following AlgoExpert's definition:
- a left child's right sibling is its parent's right child;
- a right child's right sibling is the **left child** of its parent's right sibling (null if either is missing);
- the root's right pointer becomes null.

Left pointers are unchanged.

## Building up the logic
1. With extra memory: BFS level by level and link each node to the next node in the queue. O(n) time, O(w) space. This links **all** nodes on a level, which is the LeetCode #116/#117 definition. AlgoExpert's definition is narrower (only through the parent's sibling's left child).
2. In place, the difficulty is that you overwrite `right`, destroying the link to the right child that you still need.
3. Save `left` and `right` in locals before rewiring, then choose the recursion order:
   - Recurse into the **left child first**, while the parent's `right` still points to its original right child (that is the left child's sibling).
   - Then rewire the **current node**.
   - Then recurse into the **right child**; by now the parent's `right` points to the parent's own sibling, whose `left` is the right child's sibling.
4. The comments in the code spell out this ordering; convincing yourself of it is the whole problem.

## Complexity
- Time: O(n).
- Space: O(d) recursion depth.

## Interview notes
- LeetCode #116 (perfect tree) solves the full-level version in O(1) extra space by using the already-built `next` pointers of the level above to walk across it. #117 generalizes to any tree. If you are asked the LeetCode version, use that technique.
