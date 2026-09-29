# Dijkstra's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Greedy shortest paths with a priority queue

## Problem
Given a start vertex and a directed graph with non-negative integer edge weights as an adjacency list (`edges[u]` holds `[v, weight]` pairs), return the shortest distance from the start to every vertex, or -1 if unreachable.

## Building up the logic
1. BFS gives shortest paths only when all edges weigh the same. With weights, a path with more edges can be shorter.
2. **Greedy invariant:** repeatedly take the unvisited vertex with the smallest tentative distance; that distance is final. Why: any other path to it must leave the finalized set through some vertex whose tentative distance is already at least as large, and non-negative weights can only add to it. This is exactly why **negative weights break Dijkstra**.
3. **Relaxation:** after finalizing `u`, for each edge `u -> v` with weight `w`, try `dist[v] = min(dist[v], dist[u] + w)`.
4. **Finding the minimum:**
   - linear scan over vertices: O(v^2) total, best for dense graphs;
   - binary heap: O((v + e) log v), best for sparse graphs.
5. **Lazy deletion:** instead of a decrease-key operation, push a new `(distance, vertex)` entry whenever a distance improves and skip popped entries that are stale (`d > dist[u]`). Simpler and standard in interviews.

## Complexity
| Implementation | Time | Space |
|---|---|---|
| Array scan | O(v^2 + e) | O(v) |
| Binary heap (lazy) | O((v + e) log v) | O(v + e) |

## Interview notes
- Negative edges: Bellman-Ford O(v * e), also detects negative cycles (see Detect Arbitrage). All pairs: Floyd-Warshall O(v^3).
- LeetCode #743 (Network Delay Time), #1631 (Path With Minimum Effort), #787 (Cheapest Flights Within K Stops, where plain Dijkstra needs modification). A* (very hard section) is Dijkstra plus a heuristic.
- The Dart SDK has no heap in `dart:core`; `package:collection` provides `PriorityQueue`. This file includes a minimal heap to stay dependency-free.
