# Two-Edge-Connected Graph

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Tarjan's bridge finding (DFS low-link)

## Problem
Given an undirected graph as an adjacency list, return whether it is two-edge-connected: it is connected, and removing any **single** edge leaves it connected. An empty graph counts as two-edge-connected.

## Building up the logic
1. Brute force: remove each edge and test connectivity: O(e * (v + e)).
2. An edge whose removal disconnects the graph is a **bridge**. The graph is two-edge-connected iff it is connected and has no bridges.
3. **Tarjan's idea:** run DFS and record each vertex's discovery time `disc[u]`. Define `low[u]` = the smallest discovery time reachable from u's DFS subtree using at most one **back edge** (an edge to an already-visited ancestor).
4. The tree edge `u -> v` is a bridge iff `low[v] > disc[u]`: nothing in v's subtree has a back edge to u or above, so cutting `u-v` isolates the subtree.
5. Skip the edge back to the parent (it is the tree edge itself, not a back edge). Skip it only once so a genuine parallel edge still counts as a back edge.
6. After DFS, check that every vertex was discovered (connected).

## Complexity
- Time: O(v + e).
- Space: O(v) (recursion and arrays).

## Interview notes
- LeetCode #1192 (Critical Connections in a Network) asks for all bridges: same algorithm. Articulation points (critical vertices) use `low[v] >= disc[u]` instead, with a special rule for the root.
- These are standard network-reliability questions (single points of failure).
