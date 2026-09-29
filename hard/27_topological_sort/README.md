# Topological Sort

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Kahn's algorithm (in-degree BFS) or DFS post-order

## Problem
Given a list of job ids and a list of dependencies `[prereq, job]` (the prerequisite must run before the job), return any valid order to run all jobs, or `[]` if none exists (the dependencies contain a cycle).

## Building up the logic
1. Model jobs as vertices and dependencies as directed edges `prereq -> job`. A valid order is a **topological ordering** of this directed graph; it exists iff the graph is acyclic (a DAG).
2. **Kahn's algorithm:** a job with in-degree 0 has no unmet prerequisites, so it can run now. Run it, remove its outgoing edges (decrement dependents' in-degrees), and enqueue anything that drops to 0.
3. If the queue empties before all jobs are output, the remaining jobs are on or behind a cycle: return `[]`.
4. **DFS alternative:** DFS each unvisited vertex with the three-color scheme from Cycle In Graph; append a vertex to a list when it **finishes** (post-order); reverse the list at the end. A grey-to-grey edge means a cycle.

## Complexity
- Time: O(j + d), jobs plus dependencies.
- Space: O(j + d) for the graph.

## Interview notes
- LeetCode #207/#210 (Course Schedule I/II), #269 (Alien Dictionary: build the graph from adjacent word pairs, then topological sort), build systems, package managers, spreadsheet recalculation.
- For "the lexicographically smallest order", replace the queue with a min-heap.
