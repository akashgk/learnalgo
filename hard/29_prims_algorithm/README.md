# Prim's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Grow one tree with a min-heap of crossing edges (MST)

## The problem

Given a **connected, undirected, weighted** graph as an adjacency list (`edges[u]` holds `[v, weight]`, with each edge listed at both endpoints), return a minimum spanning tree in the same format.

```
0 --3-- 1 --12-- 3
 \      |
  5     10
   \    |
     2

MST: 0-1 (3), 0-2 (5), 1-3 (12)
```

## Step 1: The idea

Start with a tree containing one vertex (vertex 0). Repeatedly add the **lightest edge that connects the tree to a vertex outside it**. After `v - 1` additions, the tree spans the graph.

This is correct by the **cut property** (see Kruskal's Algorithm, hard 28): the tree and the rest of the vertices form a split, and the lightest edge crossing it is always safe to add.

## Step 2: Finding the lightest crossing edge

Keep all edges that leave the current tree in a **min-heap** keyed by weight:

1. Add vertex 0: push all its edges.
2. Pop the lightest edge. If its far endpoint is already in the tree, the edge is **stale** (both ends are inside): skip it.
3. Otherwise add the edge and the new vertex, and push the new vertex's edges to outside vertices.
4. Repeat until the heap is empty.

This is structurally the same as Dijkstra's algorithm. The only difference is the heap key: **the edge weight** (Prim) versus **the total distance from the start** (Dijkstra). Seeing that parallel makes both easier to remember.

## Step 3: The code

<!-- CODE:START -->

Full source: [`prims_algorithm.dart`](prims_algorithm.dart) (run it with `dart run`).

```dart
// Prim's Algorithm: MST grown from vertex 0 using a min-heap of crossing edges.
// Input/output: edges[u] = [[v, w], ...] (undirected, both directions listed).
// O(e log e) time, O(v + e) space. Assumes a connected graph.

List<List<List<int>>> primsAlgorithm(List<List<List<int>>> edges) {
  final inTree = List<bool>.filled(edges.length, false);
  final mst = List.generate(edges.length, (_) => <List<int>>[]);
  if (edges.isEmpty) return mst;
  final heap = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (w, from, to)

  void addVertex(int u) {
    inTree[u] = true;
    for (final [v, w] in edges[u]) {
      if (!inTree[v]) heap.push((w, u, v));
    }
  }

  addVertex(0);
  while (heap.isNotEmpty) {
    final (w, u, v) = heap.pop();
    if (inTree[v]) continue; // both ends already in the tree
    mst[u].add([v, w]);
    mst[v].add([u, w]);
    addVertex(v);
  }
  return mst;
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_compare(_items[p], _items[i]) <= 0) break;
      _swap(i, p);
      i = p;
    }
  }

  T pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _compare(_items[l], _items[m]) < 0) m = l;
        if (r < _items.length && _compare(_items[r], _items[m]) < 0) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `inTree[v]` marks vertices already in the tree.
- `addVertex(u)` marks `u` and pushes its edges to vertices not yet in the tree, as `(weight, from, to)` records.
- The main loop pops the lightest edge, skips stale ones, and adds the rest to the MST (both directions) before expanding from the new vertex.
- `_MinHeap` is a small generic binary heap.

## Step 4: Dry run

| step | heap (weight: edge) after the step | action |
|---|---|---|
| add 0 | 3: 0-1, 5: 0-2 | |
| pop 3: 0-1 | 5: 0-2, 10: 1-2, 12: 1-3 | add edge, add vertex 1 |
| pop 5: 0-2 | 10: 1-2, 12: 1-3 | add edge, add vertex 2 (2 has no new outside edges) |
| pop 10: 1-2 | 12: 1-3 | stale (2 already in tree), skip |
| pop 12: 1-3 | empty | add edge, add vertex 3 |

MST: 0-1, 0-2, 1-3.

## Complexity

| Implementation | Time | Space |
|---|---|---|
| Heap of edges (lazy, this code) | O(e log e) = O(e log v) | O(e) |
| Array of "best edge to the tree" per vertex | O(v^2) | O(v) |

The array version is better for **dense** graphs (e close to v^2).

## Common mistakes

- Forgetting to skip stale edges (adds cycles).
- Running Prim on a disconnected graph and expecting a full spanning forest (it only spans the start vertex's component; restart from each unvisited vertex, or use Kruskal).

## What to remember

Prim grows one tree, always adding the lightest edge leaving it. It is Dijkstra with "edge weight" as the key instead of "distance from the start".
