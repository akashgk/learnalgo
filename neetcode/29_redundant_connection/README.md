# Redundant Connection

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Union-find cycle detection | **Source:** LeetCode 684; NeetCode 150

## The problem

A graph started as a tree with `n` nodes (labeled 1..n), then **one extra edge** was added. Return an edge that can be removed so the result is a tree again. If there are several answers, return the one that appears **last** in the input.

```
[[1, 2], [1, 3], [2, 3]]                  ->  [2, 3]
[[1, 2], [2, 3], [3, 4], [1, 4], [1, 5]]  ->  [1, 4]
```

## Step 1: What the extra edge does

A tree with n nodes has n - 1 edges and no cycle. Adding one edge creates **exactly one cycle**. Removing any edge on that cycle restores a tree. The problem wants the cycle edge that appears **last** in the input.

## Step 2: Process edges in order

Add edges one at a time and keep track of which nodes are connected. The first edge whose two endpoints are **already connected** closes the cycle. Every other cycle edge came earlier in the input (they were added without closing anything), so this edge is the last cycle edge in input order: exactly the answer.

"Are these two nodes already connected, and if not, connect them" is the **union-find** (disjoint set union) interface (AlgoExpert medium 35 Union Find):

- `find(x)`: the representative of x's component.
- `union(a, b)`: merge two components.

## Step 3: Making union-find fast

- **Path compression** (here, path halving): while walking to the root, point nodes closer to it.
- **Union by rank**: attach the shorter tree under the taller one.

Together they make each operation nearly O(1) amortized (inverse Ackermann).

## Step 4: The code

<!-- CODE:START -->

Full source: [`redundant_connection.dart`](redundant_connection.dart) (run it with `dart run`).

```dart
// Redundant Connection: a tree of n nodes (1..n) plus one extra edge. Return the edge that can be
// removed to leave a tree; if several work, the one that appears last in the input.
// Union-find: the first edge whose endpoints are already connected closes the cycle.
// O(n * alpha(n)) time, O(n) space.

List<int> findRedundantConnection(List<List<int>> edges) {
  final parent = List<int>.generate(edges.length + 1, (i) => i);
  final rank = List<int>.filled(edges.length + 1, 0);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]]; // path halving
      x = parent[x];
    }
    return x;
  }

  for (final e in edges) {
    final a = find(e[0]), b = find(e[1]);
    if (a == b) return e; // already connected: this edge closes the only cycle
    // Union by rank keeps the trees shallow.
    if (rank[a] < rank[b]) {
      parent[a] = b;
    } else if (rank[a] > rank[b]) {
      parent[b] = a;
    } else {
      parent[b] = a;
      rank[a]++;
    }
  }
  return const []; // unreachable for valid input
}
```

<!-- CODE:END -->

### Walkthrough

- `parent[i] = i` initially: every node is its own component. Index 0 is unused (labels start at 1).
- `if (a == b) return e;` the endpoints already share a root.
- The rank branches implement union by rank.

## Step 5: Dry run

`[[1, 2], [2, 3], [3, 4], [1, 4], [1, 5]]`:

| edge | find(u), find(v) | action |
|---|---|---|
| [1, 2] | 1, 2 | union |
| [2, 3] | 1, 3 | union |
| [3, 4] | 1, 4 | union |
| [1, 4] | 1, 1 | **same component: return [1, 4]** |

## Complexity

- Time: **O(n * alpha(n))**, effectively O(n).
- Space: **O(n)**.

## Edge cases

- The extra edge closes a cycle through all nodes: still the first edge whose endpoints are connected.
- The redundant edge appears last in the input (the first example).

## Common mistakes

- Returning the first edge of the cycle instead of the last.
- DFS-based cycle detection per edge (O(n^2), still accepted, but union-find is the intended answer).
- Forgetting that labels start at 1 (sizing `parent` as n instead of n + 1).

## Follow-ups you should be ready for

1. **Redundant Connection II (LeetCode 685).** Directed graph: also handle a node with two parents.
2. **Graph Valid Tree.** neetcode 30: the same cycle check plus an edge count.
3. **Number of connected components.** Count successful unions: `n - unions`.

## What to remember

Adding edges in order with union-find, the first edge whose endpoints are already connected closes the cycle, and it is the last cycle edge in the input.
