# Largest Island

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Label connected components, then evaluate each candidate cell

## Problem
A matrix uses **0 for land and 1 for water** (this is AlgoExpert's convention; LeetCode's version flips it). An island is a group of 4-directionally connected land cells. You may change at most one water cell into land. Return the size of the largest island possible.

## Building up the logic
1. Brute force: for each water cell, flip it and run a full flood fill to find the largest island. O((w*h)^2).
2. Flipping a water cell merges the islands **touching it**. The new size is `1 + sum of the sizes of the distinct neighboring islands`.
3. So precompute: flood-fill every island once, writing an island **id** into each land cell and recording `sizes[id]`.
4. For each water cell, collect the ids of its up to 4 neighbors in a **set** (two neighbors may belong to the same island; counting it twice is the classic bug), and sum their sizes plus one.
5. Also consider the case with no water cells at all (the answer is the existing largest island) and the all-water case (answer 1).

## Complexity
- Time: O(w * h).
- Space: O(w * h) for ids and the DFS stack.

## Interview notes
- LeetCode #827 (Making A Large Island). The "label components with ids, then answer queries in O(1) per cell" idea is widely reusable.
