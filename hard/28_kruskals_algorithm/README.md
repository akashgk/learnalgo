# Kruskal's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Sort edges + Union-Find (MST)

## Problem
Given an undirected, weighted graph as an adjacency list (`edges[u]` contains `[v, weight]`, and every edge appears in both endpoints' lists), return a minimum spanning tree in the same format. If the graph is disconnected, return a minimum spanning forest.

## Building up the logic
1. A spanning tree connects all vertices with `v - 1` edges and no cycles. We want the one with the smallest total weight.
2. **Cut property:** for any partition of the vertices, the lightest edge crossing it belongs to some MST. Kruskal applies this greedily.
3. **Algorithm:** sort all edges by weight. Walk them in order; add an edge if its endpoints are in different components, otherwise skip it (it would close a cycle).
4. "Are these in the same component? If not, merge them" is exactly Union-Find (see medium: Union Find). With path compression and union by rank each check is near O(1).
5. Collect each undirected edge once (`u < v`) to avoid processing duplicates.

## Complexity
- Time: O(e log e) for sorting (Union-Find work is O(e * alpha(v))).
- Space: O(v + e).

## Kruskal vs Prim
- Kruskal: edge-centric, great for sparse graphs or when edges are already sorted; handles forests naturally.
- Prim: vertex-centric with a heap, O(e log v); preferable for dense graphs (O(v^2) with an array).

## Interview notes
- LeetCode #1584 (Min Cost to Connect All Points) and #1135 (Connecting Cities With Minimum Cost). Real uses: network design, clustering (stop Kruskal early to get k clusters).
