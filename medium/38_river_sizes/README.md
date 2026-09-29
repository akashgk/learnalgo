# River Sizes

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Connected components on a grid (DFS/BFS flood fill)

## Problem
A 2D matrix contains only 0s (land) and 1s (river). Rivers are made of horizontally or vertically adjacent 1s (not diagonal). Return the sizes of all rivers, in any order.

## Building up the logic
1. A grid is an implicit graph: cells are nodes, edges connect 4-directional neighbors.
2. A river is a **connected component** of 1-cells. Counting component sizes = flood fill from every unvisited 1.
3. Scan every cell. When you find an unvisited 1, run DFS/BFS from it, count the cells reached, and mark them visited so they are not counted again.
4. Mark cells visited when you push them, not when you pop them, to avoid duplicates in the stack.
5. Iterative DFS avoids stack overflow on huge rivers (a 1000x1000 all-ones grid would need 10^6 recursion frames).

## Complexity
- Time: O(w * h): each cell is pushed at most once and checks 4 neighbors.
- Space: O(w * h) for `visited` and the stack. You can drop `visited` by overwriting 1s with 0s in the input, if mutation is allowed.

## Interview notes
- LeetCode #200 (Number of Islands) and #695 (Max Area of Island) are the same algorithm. This is one of the most asked Google/Amazon questions; be able to write it in under 10 minutes.
- Alternative: Union-Find over cells, useful when land cells are added dynamically (#305).
