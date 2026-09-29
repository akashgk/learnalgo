# Detect Arbitrage

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Log transform + Bellman-Ford negative cycle detection

## Problem
Given a complete matrix of currency exchange rates (`rates[i][j]` = units of j received per unit of i), return whether an arbitrage opportunity exists: a sequence of exchanges that starts and ends in the same currency with more money than you began with.

## Building up the logic
1. Arbitrage = a cycle whose **product** of rates exceeds 1.
2. Shortest-path algorithms work with **sums**. Take logs: `r1 * r2 * ... > 1` iff `log r1 + log r2 + ... > 0` iff `-log r1 - log r2 - ... < 0`.
3. So with edge weights `-log(rate)`, arbitrage exists iff the graph has a **negative-weight cycle**.
4. **Bellman-Ford:** relax every edge `n - 1` times. Without negative cycles, all shortest paths are final after `n - 1` rounds (a shortest path has at most `n - 1` edges). If any edge can still be relaxed in round `n`, a negative cycle exists.
5. The graph is complete, so starting from any single vertex reaches everything. Use a small epsilon to avoid reporting floating-point noise as arbitrage.

## Complexity
- Time: O(n^3): n rounds times n^2 edges.
- Space: O(n) (plus the O(n^2) transformed weights).

## Interview notes
- Why not Dijkstra? It assumes non-negative weights; the greedy finalization breaks with negative edges.
- Follow-up: return the actual cycle. Record predecessors; after the extra round, walk back n steps from a relaxed vertex to land inside the cycle, then follow predecessors until it repeats.
