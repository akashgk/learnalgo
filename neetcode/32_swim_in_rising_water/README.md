# Swim in Rising Water

**Difficulty:** Hard | **Category:** Advanced Graphs | **Pattern:** Minimax path: Dijkstra on the maximum (or binary search + BFS) | **Source:** LeetCode 778; NeetCode 150

## The problem

An `n x n` grid of distinct elevations (a permutation of `0..n*n-1`). At time `t` the water level is `t`, and you can swim between 4-directionally adjacent cells if **both** elevations are at most `t`. Swimming takes no time. Return the least time `t` at which you can get from the top-left cell to the bottom-right cell.

```
0 2
1 3      ->  3   (you must stand on the 3 at the end)
```

## Step 1: Restate it

A path is possible at time `t` exactly when every cell on it has elevation `<= t`. So the time needed for a path is the **maximum** elevation on it, and the answer is:

```
min over all paths of (max elevation on the path)
```

A **minimax path** problem.

## Step 2: Option A, binary search on t

For a fixed `t`, BFS over cells with elevation `<= t` and check whether the corner is reachable. Feasibility is monotone in `t` (a higher level only opens more cells), so binary search `t` in `[0, n*n - 1]`: O(n^2 log n).

## Step 3: Option B, Dijkstra with "max" instead of "+"

Dijkstra works for any path cost that never **decreases** as a path gets longer. Here the cost of extending a path to a neighbor is `max(current cost, neighbor elevation)`, which never decreases. So:

- min-heap of `(cost, cell)`, starting with `(grid[0][0], start)`;
- pop the cheapest cell; if already finalized, skip; else finalize it;
- push each unvisited neighbor with cost `max(cost, its elevation)`;
- the first time the target is popped, its cost is the answer.

This is the same shape as Path With Minimum Effort (LeetCode 1631) and "bottleneck" shortest paths in general.

## Step 4: The code

<!-- CODE:START -->

Full source: [`swim_in_rising_water.dart`](swim_in_rising_water.dart) (run it with `dart run`).

```dart
// Swim in Rising Water: grid[r][c] is an elevation (a permutation of 0..n*n-1). At time t you can
// swim between adjacent cells whose elevations are both <= t. Minimum t to get from the top-left
// to the bottom-right: minimize the MAXIMUM elevation along a path.
// Dijkstra variant: a path's cost is its max cell, expanded in increasing cost with a min-heap.
// O(n^2 log n) time, O(n^2) space.

int swimInWater(List<List<int>> grid) {
  final n = grid.length;
  final visited = List.generate(n, (_) => List<bool>.filled(n, false));
  final heap = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (time, r, c)
  heap.push((grid[0][0], 0, 0));
  while (true) {
    final (t, r, c) = heap.pop(); // smallest possible "highest cell so far" among the frontier
    if (visited[r][c]) continue;
    visited[r][c] = true;
    if (r == n - 1 && c == n - 1) return t;
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= n || nc >= n || visited[nr][nc]) continue;
      final next = grid[nr][nc] > t ? grid[nr][nc] : t; // the path's max so far
      heap.push((next, nr, nc));
    }
  }
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

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

- `heap.push((grid[0][0], 0, 0))`: the start cell itself must be under water, so the path cost starts at its elevation.
- `if (visited[r][c]) continue;` lazy deletion of stale heap entries.
- `next = max(grid[nr][nc], t)`.
- The `while (true)` loop always ends because the target is reachable at `t = n*n - 1`.

## Step 5: Dry run

`[[0, 2], [1, 3]]`:

| pop (t, cell) | pushes |
|---|---|
| (0, (0,0)) | (1, (1,0)), (2, (0,1)) |
| (1, (1,0)) | (3, (1,1)) |
| (2, (0,1)) | (3, (1,1)) again |
| (3, (1,1)) | target: **3** |

## Complexity

- Dijkstra: **O(n^2 log n)** time, O(n^2) space.
- Binary search + BFS: also O(n^2 log n).
- A third option, union-find: add cells in increasing elevation order and stop when the corners connect: O(n^2 alpha(n)) after sorting (the elevations are a permutation, so "sorting" is just indexing by value).

## Edge cases

- `n = 1`: the answer is `grid[0][0]`.
- A high start cell: the answer is at least `grid[0][0]` (the last test).

## Common mistakes

- Summing elevations (this is not a shortest-sum path).
- Forgetting the start cell's own elevation.
- Plain BFS without a priority queue (BFS minimizes the number of steps, not the maximum elevation).

## Follow-ups you should be ready for

1. **Path With Minimum Effort (LeetCode 1631).** Cost of a step is the height difference; minimize the maximum step: same Dijkstra.
2. **Minimum spanning tree view.** The minimax path between two nodes lies on the MST (Kruskal adds edges in increasing order until they connect).
3. **Weights on edges instead of cells.** Same algorithm with `max(cost, edgeWeight)`.

## What to remember

"Minimize the worst value along a path" is Dijkstra with `max` in place of `+`, or binary search on the threshold plus a reachability check.
