# Max Path Sum In Binary Tree

**Difficulty:** Hard | **Category:** Binary Trees | **Pattern:** Bottom-up DFS with "branch" vs "bent path"

## Problem
A path is a sequence of connected nodes where each node appears at most once; it does not need to pass through the root and contains at least one node. Values can be negative. Return the maximum sum of any path.

## Building up the logic
1. Every path has a unique highest node where it may "bend": it comes up from the left, goes through the node, and down to the right.
2. Distinguish two quantities at each node `t`:
   - **branch(t):** best sum of a path that **starts at t and goes down one side**. This is what `t` can offer to its parent, because a path through the parent can only continue into one side of `t`.
   - **bent(t):** `t.value + max(0, branch(left)) + max(0, branch(right))`. This is the best path whose highest node is `t`. It can **not** be extended upward.
3. Take `max(0, ...)` so negative branches are dropped rather than forced in.
4. The answer is the maximum `bent(t)` over all nodes. Initialize it with the root value (not 0), otherwise an all-negative tree returns the wrong answer.
5. Same shape as Binary Tree Diameter, with sums instead of heights.

## Complexity
- Time: O(n).
- Space: O(h).

## Interview notes
- LeetCode #124, a staple of Google and Meta onsites. The explanation of "what you return to the parent vs what you record as a candidate" is exactly what interviewers evaluate.
