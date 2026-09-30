# Graph Valid Tree

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Edge count + union-find (or DFS) | **Source:** LeetCode 261 (premium); NeetCode 150, Blind 75

## The problem

Given `n` nodes labeled `0..n-1` and a list of undirected edges, return whether they form a **valid tree**.

```
n = 5, edges = [[0,1], [0,2], [0,3], [1,4]]          ->  true
n = 5, edges = [[0,1], [1,2], [2,3], [1,3], [1,4]]   ->  false (cycle 1-2-3)
```

## Step 1: Definition of a tree

An undirected graph is a tree when it is **connected** and has **no cycle**. A useful theorem: for a graph with n nodes, any **two** of these three imply the third:

1. connected,
2. acyclic,
3. exactly n - 1 edges.

So check the edge count first (O(1)), and then only one of connectivity or acyclicity.

## Step 2: Why the edge count is a great first filter

- Fewer than n - 1 edges: cannot be connected.
- More than n - 1 edges: must contain a cycle.
- Exactly n - 1: the graph is a tree **if and only if** it has no cycle (equivalently, if and only if it is connected).

## Step 3: Check acyclicity with union-find

Process edges; an edge whose endpoints already share a root closes a cycle (same as neetcode 29). With n - 1 edges and no cycle, the graph must be connected, so it is a tree.

Alternative: DFS from node 0 and check that all n nodes are reached (connectivity). Either works after the edge count check.

## Step 4: The code

<!-- CODE:START -->

Full source: [`graph_valid_tree.dart`](graph_valid_tree.dart) (run it with `dart run`).

```dart
// Graph Valid Tree: do n nodes (0..n-1) and these undirected edges form a tree?
// A graph is a tree iff it has exactly n - 1 edges AND no cycle (equivalently: n - 1 edges and
// connected). Union-find detects a cycle on the first edge joining two already-connected nodes.
// O(n + E * alpha(n)) time, O(n) space.

bool validTree(int n, List<List<int>> edges) {
  if (edges.length != n - 1) return false; // too few: disconnected; too many: a cycle
  final parent = List<int>.generate(n, (i) => i);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  for (final e in edges) {
    final a = find(e[0]), b = find(e[1]);
    if (a == b) return false; // cycle
    parent[a] = b;
  }
  // n - 1 edges and no cycle: the graph is connected, so it is a tree.
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `edges.length != n - 1` rejects both "too few" and "too many".
- The union-find loop only needs `find` with path halving; union by rank is optional at this size.
- Returning true at the end relies on the theorem: n - 1 edges and no cycle.

## Step 5: Dry run

`n = 4`, edges `[[0, 1], [2, 3], [1, 0]]`: 3 edges = n - 1, so continue.

| edge | roots | action |
|---|---|---|
| [0, 1] | 0, 1 | union |
| [2, 3] | 2, 3 | union |
| [1, 0] | same root | **cycle: false** |

(It is also disconnected: {0, 1} and {2, 3}. The edge count plus the cycle check caught it.)

## Complexity

- Time: **O(n + E * alpha(n))**.
- Space: **O(n)**.

## Edge cases

- `n = 1`, no edges: a single node is a tree.
- `n = 2`, no edges: disconnected, false.
- Duplicate edges: the second copy is detected as a cycle.

## Common mistakes

- Checking only for cycles (a forest with no cycles is not a tree).
- Checking only connectivity (a connected graph with a cycle is not a tree).
- In DFS cycle detection on undirected graphs, forgetting to ignore the edge back to the parent.

## Follow-ups you should be ready for

1. **Number of Connected Components (LeetCode 323).** n minus the number of successful unions.
2. **Redundant Connection.** Find the edge that breaks tree-ness; neetcode 29.
3. **Minimum Height Trees (LeetCode 310).** Peel leaves layer by layer.

## What to remember

A tree has n - 1 edges and no cycle. Check the count first, then a union-find (or DFS) confirms the rest.
