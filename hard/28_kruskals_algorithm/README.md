# Kruskal's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Sort edges + Union-Find (minimum spanning tree)

## The problem

Given an **undirected, weighted** graph as an adjacency list (`edges[u]` contains `[v, weight]`, and every edge appears in the lists of both endpoints), return a **minimum spanning tree** (MST) in the same format. If the graph is disconnected, return a minimum spanning **forest**.

```
0 --3-- 1 --12-- 3
 \      |
  5     10
   \    |
     2

MST: edges 0-1 (3), 0-2 (5), 1-3 (12)   total weight 20   (1-2 with weight 10 is not used)
```

## Step 1: What is a minimum spanning tree?

A **spanning tree** connects all vertices using exactly `v - 1` edges and no cycles. Among all spanning trees, the MST has the smallest total weight. Uses: designing the cheapest network that connects everything (cables, roads, pipelines), clustering.

## Step 2: The greedy rule (cut property)

**Cut property:** split the vertices into any two groups. The lightest edge crossing between the groups belongs to some MST. (If an MST did not use it, adding it creates a cycle that crosses the split through some heavier edge; swapping them gives a lighter or equal tree.)

## Step 3: Kruskal's algorithm

1. Sort all edges by weight, lightest first.
2. Go through the edges in order. Add an edge if its two endpoints are **not already connected** by the edges chosen so far; otherwise skip it (it would close a cycle).
3. Stop after `v - 1` edges (or when edges run out, for a forest).

"Are these two vertices already connected? If not, connect them" is exactly what **Union-Find** answers in nearly O(1) (medium 35).

## Step 4: The code

<!-- CODE:START -->

Full source: [`kruskals_algorithm.dart`](kruskals_algorithm.dart) (run it with `dart run`).

```dart
// Kruskal's Algorithm: minimum spanning tree(s) of an undirected weighted graph.
// Input and output use the same adjacency format: edges[u] = [[v, w], ...] (both directions).
// Sort edges + Union-Find. O(e log e) time, O(v + e) space.

List<List<List<int>>> kruskalsAlgorithm(List<List<List<int>>> edges) {
  final list = <(int, int, int)>[
    for (var u = 0; u < edges.length; u++)
      for (final [v, w] in edges[u])
        if (u < v) (w, u, v), // each undirected edge once
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final parent = List<int>.generate(edges.length, (i) => i);
  final rank = List<int>.filled(edges.length, 0);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]]; // path halving
      x = parent[x];
    }
    return x;
  }

  final mst = List.generate(edges.length, (_) => <List<int>>[]);
  for (final (w, u, v) in list) {
    final ru = find(u), rv = find(v);
    if (ru == rv) continue; // would create a cycle
    if (rank[ru] < rank[rv]) {
      parent[ru] = rv;
    } else if (rank[ru] > rank[rv]) {
      parent[rv] = ru;
    } else {
      parent[rv] = ru;
      rank[ru]++;
    }
    mst[u].add([v, w]);
    mst[v].add([u, w]);
  }
  return mst;
}

int totalWeight(List<List<List<int>>> g) => g.expand((e) => e).fold(0, (s, e) => s + e[1]) ~/ 2;
```

<!-- CODE:END -->

### Walkthrough

- The list comprehension collects each undirected edge **once** (`if (u < v)`) as a `(weight, u, v)` record, then sorts by weight.
- `parent` / `rank` implement Union-Find; `find` uses **path halving** (point each node to its grandparent while walking up), a simple variant of path compression.
- For each edge: if the roots differ, union by rank and add the edge to the MST adjacency list in both directions.

## Step 5: Dry run

Sorted edges: `(3, 0-1), (5, 0-2), (10, 1-2), (12, 1-3)`.

| edge | roots | action | components after |
|---|---|---|---|
| 0-1 (3) | 0, 1 | add | {0,1} {2} {3} |
| 0-2 (5) | 0, 2 | add | {0,1,2} {3} |
| 1-2 (10) | same | skip (cycle) | |
| 1-3 (12) | 0, 3 | add | {0,1,2,3} |

Total weight 20.

## Complexity

- **Time: O(e log e)** for sorting (Union-Find work is O(e * alpha(v)), effectively linear).
- **Space: O(v + e)**.

## Kruskal vs Prim

| | Kruskal | Prim (hard 29) |
|---|---|---|
| Grows | a forest, merging components | a single tree from a start vertex |
| Core structure | sorted edges + Union-Find | min-heap of crossing edges |
| Time | O(e log e) | O(e log v) with a heap; O(v^2) with an array |
| Best for | sparse graphs, edges already sorted, forests | dense graphs (array version) |

## Common mistakes

- Processing each undirected edge twice.
- Checking for cycles by searching the partial tree (O(v) per edge) instead of Union-Find.

## Follow-ups

1. **Min Cost to Connect All Points (LeetCode #1584):** a complete graph; Kruskal or Prim.
2. **Connecting Cities With Minimum Cost (#1135).**
3. **Clustering into k groups:** run Kruskal but stop when k components remain.

## What to remember

Kruskal: sort edges, add each edge that connects two different components (Union-Find), skip the rest.
