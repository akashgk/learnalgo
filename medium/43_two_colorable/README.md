# Two-Colorable

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Bipartite check via BFS/DFS coloring

## Problem
Given an undirected graph as an adjacency list (each edge appears in both lists), return whether its vertices can be colored with two colors such that no edge connects two vertices of the same color. A self-loop makes this impossible.

## Building up the logic
1. Once one vertex's color is chosen, all its neighbors are forced to the other color, their neighbors back to the first, and so on. There is no real choice within a connected component.
2. So: color a start vertex, propagate alternating colors by DFS/BFS, and fail if you ever find an edge whose endpoints already share a color.
3. Theory to mention: a graph is bipartite iff it has **no odd-length cycle**. The triangle is the smallest counterexample.
4. Loop over all start vertices to handle disconnected graphs, even if the problem says connected.

## Complexity
- Time: O(v + e).
- Space: O(v).

## Interview notes
- LeetCode #785 (Is Graph Bipartite?) and #886 (Possible Bipartition, "split people who dislike each other into two groups").
- Union-Find alternative: for each vertex, union all its neighbors together; fail if a vertex ends up in the same set as a neighbor.
