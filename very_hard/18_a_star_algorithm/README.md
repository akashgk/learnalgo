# A* Algorithm

**Difficulty:** Very Hard | **Category:** Famous Algorithms | **Pattern:** Best-first search with an admissible heuristic

## The problem

Given a grid of 0s (free) and 1s (obstacles), a start cell, and an end cell, return the shortest path from start to end (a list of `[row, col]` cells, including both ends), moving up, down, left, or right. Return `[]` if the end is unreachable. Use the A* algorithm.

```
[[0, 0, 0, 0, 0],
 [0, 1, 1, 1, 0],
 [0, 0, 0, 0, 0],
 [1, 0, 1, 1, 1],
 [0, 0, 0, 0, 0]]

start (0, 1), end (4, 3)
->  (0,1) (0,0) (1,0) (2,0) (2,1) (3,1) (4,1) (4,2) (4,3)     (8 moves)
```

## Step 1: From BFS to Dijkstra to A*

- **BFS** finds shortest paths when every move costs the same, but it explores evenly in **all** directions, including away from the goal.
- **Dijkstra** orders exploration by `g(n)`: the known cost from the start. Same blind spreading when all costs are equal.
- **A\*** orders exploration by `f(n) = g(n) + h(n)`, where `h(n)` is an **estimate** of the remaining cost from n to the goal. Cells that look closer to the goal are explored first, which typically visits far fewer cells.

## Step 2: When is A* correct?

The heuristic must be **admissible**: it never overestimates the true remaining cost. Then the first time the goal is taken from the priority queue, its path is optimal.

If it is also **consistent** (`h(u) <= cost(u, v) + h(v)` for every move), each cell needs to be expanded only once, just like Dijkstra.

For 4-directional moves of cost 1, the **Manhattan distance** `|r - endRow| + |c - endCol|` is admissible and consistent: you cannot reach the goal in fewer moves even with no obstacles.

## Step 3: The algorithm

```
g[start] = 0; push (h(start), start) into a min-heap
while the heap is not empty:
    pop the cell with the smallest f
    if it is stale (a better g was already recorded), skip it
    if it is the goal: rebuild the path from cameFrom and return it
    for each free neighbor:
        tentative = g[current] + 1
        if tentative < g[neighbor]:
            g[neighbor] = tentative; cameFrom[neighbor] = current
            push (tentative + h(neighbor), neighbor)
return []
```

It is Dijkstra's algorithm (hard 26) with `g + h` as the priority instead of `g`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`a_star_algorithm.dart`](a_star_algorithm.dart) (run it with `dart run`).

```dart
// A* Algorithm on a grid (0 = free, 1 = obstacle), 4-directional moves of cost 1.
// Priority = g (cost so far) + h (Manhattan distance, admissible and consistent).
// Returns the path as [[row, col], ...], or [] if unreachable. O(wh log(wh)) time, O(wh) space.

List<List<int>> aStarAlgorithm(int startRow, int startCol, int endRow, int endCol, List<List<int>> graph) {
  final rows = graph.length, cols = graph[0].length;
  int h(int r, int c) => (r - endRow).abs() + (c - endCol).abs();
  const inf = 1 << 30;
  final g = List.generate(rows, (_) => List<int>.filled(cols, inf));
  final cameFrom = <(int, int), (int, int)>{};
  final open = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (f, r, c)
  g[startRow][startCol] = 0;
  open.push((h(startRow, startCol), startRow, startCol));
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  while (open.isNotEmpty) {
    final (f, r, c) = open.pop();
    if (f - h(r, c) > g[r][c]) continue; // stale heap entry
    if (r == endRow && c == endCol) {
      final path = <List<int>>[];
      (int, int)? node = (r, c);
      while (node != null) {
        path.add([node.$1, node.$2]);
        node = cameFrom[node];
      }
      return path.reversed.toList();
    }
    for (final (dr, dc) in dirs) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols || graph[nr][nc] == 1) continue;
      final tentative = g[r][c] + 1;
      if (tentative < g[nr][nc]) {
        g[nr][nc] = tentative;
        cameFrom[(nr, nc)] = (r, c);
        open.push((tentative + h(nr, nc), nr, nc));
      }
    }
  }
  return [];
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
    final top = _items.first, last = _items.removeLast();
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

- `h(r, c)` is the Manhattan distance to the goal.
- `g` holds the best known cost to reach each cell; `cameFrom` stores the parent for path reconstruction.
- `if (f - h(r, c) > g[r][c]) continue;` recovers `g` from the popped `f` and skips stale entries.
- On reaching the goal, the path is rebuilt backward via `cameFrom` and reversed.
- Neighbors outside the grid or on obstacles are skipped.

## Complexity

- **Time: O(V log V)** in the worst case (V = number of cells), the same as Dijkstra; usually much faster in practice thanks to the heuristic.
- **Space: O(V)**.

## Choosing the heuristic

| Movement | Admissible heuristic |
|---|---|
| 4 directions, cost 1 | Manhattan distance |
| 8 directions, all moves cost 1 | Chebyshev distance `max(|dx|, |dy|)` |
| 8 directions, diagonal costs sqrt(2) | octile distance |
| any direction | Euclidean distance |

`h = 0` turns A* into Dijkstra. An overestimating heuristic may return non-shortest paths (sometimes used deliberately for speed).

## Common mistakes

- A heuristic that overestimates (breaks optimality).
- Returning when the goal is **pushed** instead of when it is **popped**.
- Forgetting to skip stale heap entries.

## Follow-ups

1. **Shortest Path in Binary Matrix (LeetCode #1091):** 8 directions; BFS or A* with Chebyshev distance.
2. **Real systems:** games, robotics, route planning. For huge road networks, bidirectional search and contraction hierarchies go further; naming them is a plus.

## What to remember

A* = Dijkstra ordered by `g + h`. With an admissible heuristic, the first time the goal is popped, the path is optimal.
