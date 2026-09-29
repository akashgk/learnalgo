# Remove Islands

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Flood fill from the boundary (reverse thinking)

## Problem
A matrix of 0s (white) and 1s (black). An island is a group of 4-directionally connected 1s that does **not** touch the border (a 1 on the border, and every 1 connected to it, is safe). Replace every island's 1s with 0s and return the matrix.

## Building up the logic
1. Direct approach: flood-fill each component and check whether any of its cells touches the border; if not, erase it. Works but needs to store each component before deciding.
2. **Invert the question:** instead of finding islands, find what is **not** an island. Everything reachable from a border 1 survives.
3. Flood-fill from every border 1, marking reached cells with a temporary value (2).
4. Final pass: 2 -> 1 (survivor), remaining 1 -> 0 (island).
5. Marking in place avoids a separate visited grid.

## Complexity
- Time: O(w * h).
- Space: O(w * h) worst case for the DFS stack (a snake-shaped border-connected region).

## Interview notes
- "Start from the boundary" is a reusable trick: LeetCode #130 (Surrounded Regions) is identical, and #417 (Pacific Atlantic Water Flow) floods from each ocean's border and intersects.
