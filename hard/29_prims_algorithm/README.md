# Prim's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Grow a tree with a min-heap of crossing edges (MST)

## Problem
Given a connected, undirected, weighted graph as an adjacency list (`edges[u]` holds `[v, weight]`, edges listed in both directions), return a minimum spanning tree in the same format.

## Building up the logic
1. Start from any vertex; the tree is `{0}`.
2. **Cut property again:** the lightest edge leaving the current tree (one endpoint inside, one outside) is safe to add. Prim repeatedly adds that edge.
3. Keep all candidate edges leaving the tree in a min-heap keyed by weight. Pop the lightest; if its far endpoint is already in the tree, it is stale (skip it). Otherwise add the edge and push the new vertex's outgoing edges.
4. This is structurally Dijkstra, with the key being the **edge weight** instead of the path distance. Seeing that parallel helps you remember both.

## Complexity
| Implementation | Time | Space |
|---|---|---|
| Heap of edges (lazy, this code) | O(e log e) = O(e log v) | O(e) |
| Array of best edge per vertex (dense graphs) | O(v^2) | O(v) |

## Interview notes
- Prim on a disconnected graph only spans the start vertex's component; rerun from each unvisited vertex for a forest, or use Kruskal.
- Compare with Kruskal's README. Interviewers sometimes ask which one you would choose for a dense graph (Prim with an array) vs a sparse one (either; Kruskal is simpler with Union-Find).
