# Cycle In Graph

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** DFS three-color (back edge detection)

## Problem
A directed, unweighted graph is given as an adjacency list: `edges[i]` lists the vertices that vertex `i` points to. Return whether the graph contains a cycle (a self-loop counts).

## Building up the logic
1. A plain `visited` set is **not enough** in a directed graph. In `0 -> 1, 0 -> 2, 1 -> 2`, vertex 2 is reached twice but there is no cycle. This is the most common wrong answer; interviewers look for it.
2. A cycle exists iff DFS finds an edge to a vertex that is **still on the current recursion path** (a back edge).
3. Three states per vertex:
   - white: not visited yet
   - grey: currently on the DFS stack
   - black: finished; everything reachable from it has been explored and contains no cycle
4. Edge to grey -> cycle. Edge to black -> safe, skip. Edge to white -> recurse.
5. Launch DFS from every white vertex because the graph may be disconnected.

## Alternative
**Kahn's algorithm** (BFS topological sort): repeatedly remove vertices with in-degree 0. If some vertices are never removed, they are on or behind a cycle. Same O(v + e).

## Complexity
- Time: O(v + e).
- Space: O(v) for colors and recursion.

## Interview notes
- For **undirected** graphs, the rule is different: a visited neighbor that is not your parent means a cycle (or use Union-Find).
- LeetCode #207 (Course Schedule) is this problem in disguise.
