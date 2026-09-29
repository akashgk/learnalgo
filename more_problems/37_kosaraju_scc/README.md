# Strongly Connected Components (Kosaraju)

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Two-pass DFS (finish order, then reversed graph) | **Source:** Striver A2Z (Kosaraju's algorithm); classic algorithm

## The problem

In a **directed** graph, a strongly connected component (SCC) is a maximal set of vertices where every vertex can reach every other. Find all SCCs.

```
0 -> 1 -> 2 -> 0     (cycle)
2 -> 3
3 -> 4 -> 5 -> 3     (cycle)
6 -> 5

SCCs: {0, 1, 2}, {3, 4, 5}, {6}
```

## Step 1: Brute force

For every pair (u, v), check whether u reaches v and v reaches u: run a DFS from every vertex to get the reachability sets, O(V * (V + E)). Too slow for large graphs.

## Step 2: The condensation is a DAG

Collapse each SCC into a single node. The resulting graph has **no cycles** (a cycle between components would merge them into one). In the example: `{0,1,2} -> {3,4,5} <- {6}`.

Now think about a DFS started in a **sink** component (one with no outgoing edges to other components, like `{3,4,5}`): it visits exactly that component and nothing else. So if we knew an order that starts DFS in sink components first, each DFS tree would be exactly one SCC.

## Step 3: Getting that order

**Finish times.** Run DFS on the whole graph and record each vertex when it **finishes** (all its descendants are done). Fact: if there is an edge from component A to component B (A != B), then the **latest** finish time in A is greater than the latest finish time in B. So the vertex that finishes last belongs to a **source** component of the condensation.

We want sinks, not sources. **Reverse every edge**: sources become sinks and vice versa, but the SCCs stay the same (mutual reachability is symmetric under reversal). So:

1. DFS on the original graph, record finish order.
2. Build the reversed graph.
3. Take vertices in **decreasing** finish time. Each unvisited one starts a DFS **in the reversed graph**; everything it reaches (and has not been visited) is one SCC.

In step 3, the first vertex belongs to a source of the original condensation, which is a sink of the reversed one: its DFS cannot escape its own component. Removing that component, the argument repeats.

## Step 4: The code

<!-- CODE:START -->

Full source: [`kosaraju_scc.dart`](kosaraju_scc.dart) (run it with `dart run`).

```dart
// Strongly Connected Components with Kosaraju's algorithm.
// 1. DFS on the graph, recording vertices by finish time.
// 2. Reverse every edge.
// 3. DFS on the reversed graph in decreasing finish time; each tree is one SCC.
// O(V + E) time, O(V + E) space.

List<List<int>> kosaraju(int n, List<List<int>> edges) {
  final adj = List.generate(n, (_) => <int>[]);
  final radj = List.generate(n, (_) => <int>[]);
  for (final e in edges) {
    adj[e[0]].add(e[1]);
    radj[e[1]].add(e[0]);
  }
  final visited = List<bool>.filled(n, false);
  final order = <int>[]; // vertices in increasing finish time
  void dfs1(int u) {
    visited[u] = true;
    for (final v in adj[u]) {
      if (!visited[v]) dfs1(v);
    }
    order.add(u); // finished: all descendants are done
  }

  for (var u = 0; u < n; u++) {
    if (!visited[u]) dfs1(u);
  }
  visited.fillRange(0, n, false);
  final components = <List<int>>[];
  void dfs2(int u, List<int> component) {
    visited[u] = true;
    component.add(u);
    for (final v in radj[u]) {
      if (!visited[v]) dfs2(v, component);
    }
  }

  for (final u in order.reversed) {
    if (!visited[u]) {
      final component = <int>[];
      dfs2(u, component);
      components.add(component..sort());
    }
  }
  return components;
}
```

<!-- CODE:END -->

### Walkthrough

- `adj` and `radj` are built together.
- `dfs1` appends `u` to `order` after exploring all neighbors: that is the finish order.
- `visited` is reset, then vertices are taken from `order.reversed` (latest finish first).
- `dfs2` walks the reversed graph and collects one component.

## Step 5: Dry run

First pass from 0: `0 -> 1 -> 2 -> (0 visited) -> 3 -> 4 -> 5 -> (3 visited)`. Finish order: 5, 4, 3, 2, 1, 0. Then from 6: 5 is visited, 6 finishes. `order = [5, 4, 3, 2, 1, 0, 6]`.

Reversed edges: `1->0, 2->1, 0->2, 3->2, 4->3, 5->4, 3->5, 5->6`.

| start (decreasing finish) | reversed DFS reaches | component |
|---|---|---|
| 6 | nothing new (6 has no reversed out-edges) | {6} |
| 0 | 2, 1 | {0, 1, 2} |
| 1, 2 | already visited | |
| 3 | 5, 4 (2 is visited) | {3, 4, 5} |

## Complexity

- Time: **O(V + E)**: two DFS passes and one reversal.
- Space: **O(V + E)** for the reversed graph, plus recursion depth O(V).

## Edge cases

- A DAG: every vertex is its own SCC.
- A single cycle through all vertices: one SCC.
- Self-loops and isolated vertices.

## Common mistakes

- Using discovery order instead of finish order.
- Running the second pass on the original graph instead of the reversed one.
- Processing in increasing finish order.
- Deep recursion on large graphs (use an iterative DFS in production).

## Follow-ups you should be ready for

1. **Tarjan's algorithm.** One DFS with low-link values and a stack; also O(V + E), no reversed graph. Related to bridges and articulation points (AlgoExpert very_hard 22 Two-Edge-Connected Graph uses low-link ideas).
2. **Condensation DAG.** Number the components, then add an edge between components for each cross edge. Used in 2-SAT and in "minimum edges to make the graph strongly connected".
3. **Is the whole graph strongly connected?** One DFS from any vertex on the graph and one on the reversed graph must both reach everything.

## What to remember

Finish times from one DFS give the components in topological order of the condensation. Reversing the edges turns the first one into a sink, so a DFS from it cannot leak into other components.
