# Dijkstra's Algorithm

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Greedy shortest paths with a priority queue

## The problem

Given a starting vertex and a **directed** graph with **non-negative** integer edge weights, represented as an adjacency list where `edges[u]` holds `[v, weight]` pairs, return the length of the shortest path from the start to every vertex. Use -1 for unreachable vertices.

```
start = 0
edges = [
  [[1, 7]],                     // 0 -> 1 (7)
  [[2, 6], [3, 20], [4, 3]],    // 1 -> 2 (6), 1 -> 3 (20), 1 -> 4 (3)
  [[3, 14]],                    // 2 -> 3 (14)
  [[4, 2]],                     // 3 -> 4 (2)
  [],
  [],
]
->  [0, 7, 13, 27, 10, -1]
```

## Step 1: Why not BFS?

BFS finds shortest paths when every edge has the **same** cost: fewer edges means shorter. With weights, a path with more edges can be cheaper. We need to explore in order of **distance**, not number of edges.

## Step 2: The greedy idea

Keep a tentative distance for every vertex (infinity at first, 0 for the start). Repeatedly:

1. Pick the **unfinished vertex with the smallest tentative distance**. Its distance is now **final**.
2. **Relax** its outgoing edges: for each edge `u -> v` with weight `w`, if `dist[u] + w < dist[v]`, improve `dist[v]`.

**Why is the picked distance final?** Any other path to that vertex must leave the set of finished vertices through some unfinished vertex, whose tentative distance is already at least as large. Adding more edges (all **non-negative**) can only increase it. So no better path exists.

That argument breaks with **negative** edges: a later negative edge could make a longer-looking path cheaper. That is why Dijkstra requires non-negative weights.

## Step 3: Finding the minimum efficiently

- **Scan all vertices** each time: O(v) per step, O(v^2) total. Best for dense graphs.
- **Min-heap (priority queue)** of `(distance, vertex)`: O(log v) per operation, **O((v + e) log v)** total. Best for sparse graphs.

**Lazy deletion:** instead of a "decrease key" operation, push a new `(newDistance, v)` entry whenever `dist[v]` improves. When you pop an entry whose distance is larger than the current `dist[v]`, it is **stale**: skip it. Simpler and standard in interviews.

## Step 4: The code

<!-- CODE:START -->

Full source: [`dijkstras_algorithm.dart`](dijkstras_algorithm.dart) (run it with `dart run`).

```dart
// Dijkstra's Algorithm: shortest distances from `start` in a directed graph with
// non-negative weights. edges[u] = [[v, weight], ...]. -1 for unreachable vertices.
// Binary heap with lazy deletion: O((v + e) log v) time, O(v + e) space.

List<int> dijkstrasAlgorithm(int start, List<List<List<int>>> edges) {
  const inf = 1 << 62;
  final dist = List<int>.filled(edges.length, inf)..[start] = 0;
  final heap = _MinHeap<(int, int)>((a, b) => a.$1.compareTo(b.$1))..push((0, start));
  while (heap.isNotEmpty) {
    final (d, u) = heap.pop();
    if (d > dist[u]) continue; // stale entry: u was already finalized with a shorter distance
    for (final [v, w] in edges[u]) {
      if (d + w < dist[v]) {
        dist[v] = d + w;
        heap.push((dist[v], v));
      }
    }
  }
  return [for (final d in dist) d == inf ? -1 : d];
}

/// Minimal binary heap (the Dart core SDK has no priority queue).
class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[parent], _items[i]) <= 0) break;
      _swap(i, parent);
      i = parent;
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

- `dist` starts at "infinity" except `dist[start] = 0`.
- The heap holds `(distance, vertex)` records, ordered by distance.
- `if (d > dist[u]) continue;` skips stale entries.
- Relaxation pushes a new entry for every improvement.
- `_MinHeap` is a small generic binary heap (Dart's core library has none; see Min Heap Construction, medium 46).

## Step 5: Dry run

| pop (dist, vertex) | relaxations | dist after |
|---|---|---|
| (0, 0) | 1: 7 | [0, 7, inf, inf, inf, inf] |
| (7, 1) | 2: 13, 3: 27, 4: 10 | [0, 7, 13, 27, 10, inf] |
| (10, 4) | none | unchanged |
| (13, 2) | 3: 13 + 14 = 27 (not better) | unchanged |
| (27, 3) | 4: 29 (not better) | unchanged |

Vertex 5 was never reached: -1. Result `[0, 7, 13, 27, 10, -1]`.

## Complexity

| Implementation | Time | Space |
|---|---|---|
| Linear scan for the minimum | O(v^2 + e) | O(v) |
| Binary heap with lazy deletion | O((v + e) log v) | O(v + e) |

## Common mistakes

- Using Dijkstra with negative edge weights.
- Not skipping stale heap entries (correct but slower, and can confuse explanations).
- Marking a vertex finished when it is **pushed** instead of when it is **popped**.

## Related algorithms

| Algorithm | Handles | Time |
|---|---|---|
| BFS | unit weights | O(v + e) |
| Dijkstra | non-negative weights | O((v + e) log v) |
| Bellman-Ford | negative weights, detects negative cycles | O(v * e) (see Detect Arbitrage, very hard 21) |
| Floyd-Warshall | all pairs | O(v^3) |
| A* | Dijkstra + a heuristic toward one target | see very hard 18 |

## Follow-ups

1. **Network Delay Time (LeetCode #743)**, **Path With Minimum Effort (#1631)**, **Cheapest Flights Within K Stops (#787,** needs an extra state for the number of stops).
2. **Return the actual paths:** store `previous[v]` on each successful relaxation.

## What to remember

Always finalize the closest unfinished vertex, then relax its edges. A min-heap makes "closest" fast; non-negative weights make it correct.
