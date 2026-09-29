# Airport Connections

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Strongly connected components + condensation DAG

## Problem
Given a list of airports, one-way routes between them, and a starting airport, return the minimum number of new one-way routes (all departing from the starting airport) needed so that every airport is reachable from the start.

## Building up the logic
1. Airports already reachable from the start need nothing.
2. Adding a route `start -> X` makes everything reachable from `X` reachable. So we want to pick as few `X` as possible covering all unreachable airports.
3. **Cycles:** airports on a common cycle are mutually reachable; one route into the cycle covers all of them. Collapse each **strongly connected component** (SCC) into one node. The result (the condensation) is a DAG.
4. In a DAG, every node is reachable from some **source** (a node with in-degree 0). Sources cannot be reached from anything else, so each source (other than the start's own component) needs its own new route, and routes to all sources suffice. Answer = number of source components excluding the start's component.
5. **Kosaraju's algorithm:** DFS to record finish order; DFS on the reversed graph in reverse finish order; each DFS tree is an SCC. Tarjan's algorithm does it in one pass with low-link values.

## Complexity
- Time: O(a + r).
- Space: O(a + r).

## Interview notes
- AlgoExpert's reference solution uses a greedy over "how many unreachable airports each unreachable airport can reach" (O(a * (a + r)) time). The SCC answer is both faster and easier to prove optimal; present it if you know SCCs.
- Related: "minimum edges to make a DAG strongly connected" = `max(#sources, #sinks)` (a classic contest result).
- Recursive DFS may overflow on very deep graphs; mention an iterative version.
