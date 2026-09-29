# Two-Edge-Connected Graph

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Tarjan's bridge finding (DFS low-link values)

## The problem

Given an **undirected** graph as an adjacency list, return whether it is **two-edge-connected**: it is connected, and removing **any single edge** still leaves it connected. An empty graph counts as two-edge-connected.

```
[[1, 2, 5], [0, 2], [0, 1, 3], [2, 4, 5], [3, 5], [0, 3, 4]]  ->  true
[[1], [0, 2], [1]]  (a path 0 - 1 - 2)                          ->  false
```

## Step 1: Rephrase with bridges

An edge whose removal disconnects the graph is called a **bridge**. So:

```
two-edge-connected  <=>  connected  and  no bridges
```

In the path `0 - 1 - 2`, both edges are bridges.

## Step 2: Brute force

Remove each edge in turn and test connectivity with a DFS: O(e * (v + e)).

## Step 3: When is an edge a bridge? (DFS tree view)

Run a DFS. Edges used by the DFS form a **tree**; every other edge is a **back edge** connecting a vertex to one of its ancestors.

A tree edge `u -> v` (u the parent) is **not** a bridge iff some vertex in v's subtree has a back edge to u or to an ancestor of u: that back edge is an alternative route around `u -> v`. If no such back edge exists, cutting `u -> v` isolates v's subtree: a bridge.

## Step 4: Low-link values

Give every vertex a **discovery time** `disc[u]` (the order in which DFS reaches it). Define:

```
low[u] = the smallest discovery time reachable from u's subtree using at most one back edge
```

Compute it during the DFS:

- start with `low[u] = disc[u]`;
- for a back edge `u -> w`: `low[u] = min(low[u], disc[w])`;
- after returning from a child v: `low[u] = min(low[u], low[v])`.

Then the tree edge `u -> v` is a **bridge iff `low[v] > disc[u]`**: nothing in v's subtree reaches u or above.

**Skip the parent edge once:** the edge back to the parent is the tree edge itself, not a back edge. Skip it only once, so that a genuine **parallel** edge to the parent still counts as an alternative route.

Finally, check that DFS from vertex 0 reached every vertex (connectivity).

## Step 5: The code

<!-- CODE:START -->

Full source: [`two_edge_connected_graph.dart`](two_edge_connected_graph.dart) (run it with `dart run`).

```dart
// Two-Edge-Connected Graph: connected, and removing any single edge keeps it connected
// (no bridges). Tarjan's low-link DFS. O(v + e) time, O(v) space.

bool twoEdgeConnectedGraph(List<List<int>> edges) {
  final n = edges.length;
  if (n == 0) return true;
  final disc = List<int>.filled(n, -1); // discovery time
  final low = List<int>.filled(n, 0); // earliest discovery time reachable via one back edge
  var time = 0;
  var hasBridge = false;

  void dfs(int u, int parent) {
    disc[u] = low[u] = time++;
    var skippedParent = false;
    for (final v in edges[u]) {
      if (v == parent && !skippedParent) {
        skippedParent = true; // skip the tree edge once (parallel edges still count)
        continue;
      }
      if (disc[v] == -1) {
        dfs(v, u);
        if (low[v] < low[u]) low[u] = low[v];
        if (low[v] > disc[u]) hasBridge = true; // v's subtree cannot reach above u
      } else if (disc[v] < low[u]) {
        low[u] = disc[v];
      }
    }
  }

  dfs(0, -1);
  final connected = disc.every((d) => d != -1);
  return connected && !hasBridge;
}
```

<!-- CODE:END -->

### Walkthrough

- `disc` and `low` are the arrays from Step 4; `time` is the discovery counter.
- `skippedParent` implements "skip the parent edge exactly once".
- For unvisited neighbors: recurse, propagate `low`, test the bridge condition.
- For visited neighbors (back edges): update `low` with their discovery time.
- The result requires full connectivity and no bridges.

## Step 6: Dry run on the path `0 - 1 - 2`

| vertex | disc | low after DFS |
|---|---|---|
| 0 | 0 | 0 |
| 1 | 1 | 1 (its only other neighbor, 2, cannot reach above 1) |
| 2 | 2 | 2 |

Edge `1 -> 2`: `low[2] = 2 > disc[1] = 1`: bridge. Answer: false.

In the first example, every tree edge has a back edge around it (the graph consists of overlapping cycles), so no `low[v] > disc[u]` occurs, and the graph is connected: true.

## Complexity

- **Time: O(v + e)**: one DFS.
- **Space: O(v)**.

## Common mistakes

- Treating the edge back to the parent as a back edge (then nothing is ever a bridge).
- Forgetting the connectivity check (a disconnected graph with no bridges is not two-edge-connected).
- Using `>=` (that is the articulation-point condition, a different question).

## Follow-ups

1. **Critical Connections in a Network (LeetCode #1192):** list all bridges.
2. **Articulation points (critical vertices):** a non-root vertex u is critical if some child v has `low[v] >= disc[u]`; the root is critical if it has two or more DFS children.
3. **Network reliability:** bridges and articulation points are single points of failure.

## What to remember

Tarjan's low-link: `low[v]` is how high v's subtree can climb with one back edge. A tree edge `u -> v` is a bridge iff `low[v] > disc[u]`.
