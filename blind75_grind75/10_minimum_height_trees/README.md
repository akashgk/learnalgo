# Minimum Height Trees

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Peel leaves layer by layer (find the tree's center) | **Source:** LeetCode 310; Grind 75

## The problem

A tree has `n` nodes (`0..n-1`) and `n - 1` undirected edges. Choosing any node as the root gives a rooted tree with some height. Return **all** roots that give the minimum height.

```
n = 4, edges = [[1,0], [1,2], [1,3]]               ->  [1]
n = 6, edges = [[3,0], [3,1], [3,2], [3,4], [5,4]] ->  [3, 4]
```

## Step 1: Brute force

BFS from every node to compute its height: O(n^2). Too slow for n = 2 * 10^4.

## Step 2: What makes a root good?

The height from a root is its distance to the farthest node. The farthest nodes are always ends of the tree's **longest path** (its diameter). To minimize the distance to both ends, the root should sit in the **middle** of that path: the tree's **center**. A path with an odd number of nodes has one middle node; with an even number, two. So the answer always has **one or two** nodes.

## Step 3: Find the center by peeling leaves

Remove all current leaves (degree-1 nodes) at once. The longest path loses one node at each end, so its middle stays the same. Repeat until at most two nodes remain: they are the center.

This is a topological-sort-like BFS (Kahn's algorithm on an undirected tree): a node becomes a leaf when its degree drops to 1.

## Step 4: The code

<!-- CODE:START -->

Full source: [`minimum_height_trees.dart`](minimum_height_trees.dart) (run it with `dart run`).

```dart
// Minimum Height Trees: in an undirected tree with n nodes, return every node that, chosen as the
// root, gives the minimum height. Those are the 1 or 2 centers of the tree's longest path.
// Peel leaves layer by layer (topological trimming); the last 1 or 2 nodes are the answer.
// O(n) time and space.

List<int> findMinHeightTrees(int n, List<List<int>> edges) {
  if (n == 1) return [0];
  final adj = List.generate(n, (_) => <int>{});
  for (final e in edges) {
    adj[e[0]].add(e[1]);
    adj[e[1]].add(e[0]);
  }
  var leaves = [
    for (var v = 0; v < n; v++)
      if (adj[v].length == 1) v,
  ];
  var remaining = n;
  while (remaining > 2) {
    remaining -= leaves.length;
    final next = <int>[];
    for (final leaf in leaves) {
      final neighbor = adj[leaf].first; // a leaf has exactly one neighbor left
      adj[neighbor].remove(leaf);
      if (adj[neighbor].length == 1) next.add(neighbor); // it just became a leaf
    }
    leaves = next;
  }
  return leaves..sort();
}
```

<!-- CODE:END -->

### Walkthrough

- `adj` uses sets so a removed edge disappears in O(1).
- `remaining` counts nodes not yet peeled; the loop stops at 2 or fewer.
- `adj[leaf].first` is the leaf's only neighbor. Removing the leaf may turn that neighbor into a new leaf.
- `n == 1` is handled up front (a single node has degree 0, not 1).

## Step 5: Dry run

Second example. Degrees: 0:1, 1:1, 2:1, 3:4, 4:2, 5:1.

| round | leaves removed | remaining | new leaves |
|---|---|---|---|
| 1 | 0, 1, 2, 5 | 2 | 3 (only neighbor 4 left), 4 (only neighbor 3 left) |

Two nodes remain: **[3, 4]**. The longest path 0-3-4-5 has 4 nodes; its middle is 3 and 4.

## Complexity

- Time: **O(n)**: each node is peeled once, each edge removed once.
- Space: **O(n)**.

## Edge cases

- `n = 1`: `[0]`.
- `n = 2`: both nodes.
- A path: its middle node (or two middle nodes).

## Common mistakes

- Stopping when one node remains (the answer can be two nodes).
- Peeling leaves one at a time instead of in layers (removes from one end only; the center shifts).
- Missing the `n == 1` case.

## Follow-ups you should be ready for

1. **Tree diameter.** BFS from any node to the farthest node u, then BFS from u: the farthest distance is the diameter. The center is the middle of that path (another way to solve this problem).
2. **Sum of distances from every node (LeetCode 834).** Rerooting DP.
3. **Course Schedule.** The same in-degree peeling on a directed graph; AlgoExpert hard 27.

## What to remember

The best roots are the center of the tree's longest path: one or two nodes. Peeling leaves layer by layer converges to exactly those.
