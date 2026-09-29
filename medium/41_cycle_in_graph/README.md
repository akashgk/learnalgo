# Cycle In Graph

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** DFS with three colors (back-edge detection)

## The problem

A **directed**, unweighted graph is given as an adjacency list: `edges[i]` lists the vertices that vertex `i` points to. Return whether the graph contains a cycle. A self-loop counts as a cycle.

```
edges = [[1, 3], [2, 3, 4], [0], [], [2, 5], []]   ->  true   (0 -> 1 -> 2 -> 0)
edges = [[1, 2], [2], []]                          ->  false
```

## Step 1: Why a plain "visited" set is wrong

Take `edges = [[1, 2], [2], []]`: `0 -> 1 -> 2` and `0 -> 2`. DFS from 0 visits 1, then 2. Back at 0, it follows the edge to 2 again: 2 is already visited. A naive "visited again means cycle" answer says true. But there is **no cycle**: 2 was reached by two different paths, which is allowed in a directed graph.

This is the most common wrong answer to this question, and interviewers look for it.

## Step 2: What actually indicates a cycle

A directed cycle exists if and only if DFS finds an edge to a vertex that is **still on the current recursion path** (still being explored). Such an edge is a **back edge**: it points back to an ancestor in the DFS tree, closing a loop.

So we need three states per vertex:

| color | meaning |
|---|---|
| white | not visited yet |
| grey | on the current DFS path (entered, not finished) |
| black | finished: fully explored, and no cycle was found from it |

Rules for an edge `u -> v` during DFS of `u`:

- `v` grey: back edge, **cycle**.
- `v` black: already fully explored, safe to skip (this is the `0 -> 2` case above).
- `v` white: recurse.

After exploring all of `u`'s edges, color `u` black.

## Step 3: The code

<!-- CODE:START -->

Full source: [`cycle_in_graph.dart`](cycle_in_graph.dart) (run it with `dart run`).

```dart
// Cycle In Graph (directed, adjacency list). DFS with three colors:
// white = unvisited, grey = on the current DFS path, black = fully explored.
// A grey-to-grey edge is a back edge, i.e. a cycle. O(v + e) time, O(v) space.

enum _Color { white, grey, black }

bool cycleInGraph(List<List<int>> edges) {
  final color = List<_Color>.filled(edges.length, _Color.white);

  bool dfs(int node) {
    color[node] = _Color.grey;
    for (final next in edges[node]) {
      if (color[next] == _Color.grey) return true;
      if (color[next] == _Color.white && dfs(next)) return true;
    }
    color[node] = _Color.black;
    return false;
  }

  for (var v = 0; v < edges.length; v++) {
    if (color[v] == _Color.white && dfs(v)) return true;
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- `enum _Color { white, grey, black }` makes the three states explicit.
- `dfs(node)` colors the node grey, checks each neighbor by the rules above, and colors it black when done.
- The outer loop starts a DFS from every white vertex, because the graph may be disconnected.

## Step 4: Dry run on the first example

| action | colors (0..5) |
|---|---|
| dfs(0): grey | G W W W W W |
| edge 0 -> 1, dfs(1): grey | G G W W W W |
| edge 1 -> 2, dfs(2): grey | G G G W W W |
| edge 2 -> 0: 0 is **grey** | cycle found, return true |

On `[[1, 2], [2], []]`: dfs(0) -> dfs(1) -> dfs(2); 2 finishes (black), 1 finishes (black). Back in 0, the edge `0 -> 2` finds black: skip. 0 finishes. No cycle.

## Complexity

- **Time: O(v + e)**: each vertex is processed once and each edge examined once.
- **Space: O(v)** for colors and recursion depth.

## Alternative: Kahn's algorithm

Repeatedly remove vertices with in-degree 0 (see Topological Sort, hard 27). If some vertices are never removed, they are on a cycle or depend on one. Same complexity, iterative, and it also gives a topological order when there is no cycle.

## Undirected graphs are different

In an undirected graph, every edge appears in both directions, so the rule becomes: a visited neighbor that is **not your parent** in the DFS tree means a cycle. Union-Find is another option: an edge whose endpoints are already in the same set closes a cycle.

## Common mistakes

- Using a single visited set for a directed graph.
- Forgetting to launch DFS from every unvisited vertex.
- Coloring a vertex black before exploring all of its edges.

## Follow-ups

1. **Course Schedule (LeetCode #207):** this problem in disguise (can all courses be finished = no cycle in prerequisites).
2. **Find Eventual Safe States (#802):** vertices that are black in the end and never lead to a cycle.
3. **Return the cycle itself:** keep parent pointers; when a back edge `u -> v` is found, walk from u back to v.

## What to remember

Directed cycle = back edge = an edge to a grey (in-progress) vertex. Visited-but-finished (black) is fine.
