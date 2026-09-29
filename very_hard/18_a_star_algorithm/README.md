# A* Algorithm

**Difficulty:** Very Hard | **Category:** Famous Algorithms | **Pattern:** Best-first search with an admissible heuristic

## Problem
Given a grid of 0s (free) and 1s (obstacles), a start cell, and an end cell, return the shortest path (list of `[row, col]` from start to end, inclusive) moving up/down/left/right, or `[]` if the end is unreachable. Use A*.

## Building up the logic
1. BFS finds the shortest path in an unweighted grid but explores in all directions equally.
2. **Dijkstra** orders exploration by `g(n)`, the known cost from the start.
3. **A\*** orders by `f(n) = g(n) + h(n)`, where `h(n)` estimates the remaining cost to the goal. With a good estimate, nodes pointing toward the goal are explored first, often far fewer nodes than Dijkstra.
4. **Correctness condition:** `h` must be **admissible** (never overestimates the true remaining cost). If it is also **consistent** (`h(u) <= cost(u, v) + h(v)`), the first time the goal is popped, its path is optimal, and each node needs to be expanded at most once. Manhattan distance is both, for 4-directional unit moves.
5. Implementation mirrors Dijkstra: min-heap on `f`, relax neighbors with `g + 1`, store `cameFrom` to rebuild the path, skip stale heap entries.

## Complexity
- Time: O(V log V) worst case (V = w * h cells), same as Dijkstra; typically much faster in practice.
- Space: O(V).

## Interview notes
- Heuristic choice by movement model: 4-directional -> Manhattan; 8-directional with unit diagonals -> Chebyshev; any angle -> Euclidean. `h = 0` turns A* into Dijkstra.
- Used in games, robotics, and route planning. For huge graphs, bidirectional search and contraction hierarchies (Google Maps style) go further; naming them is a plus.
