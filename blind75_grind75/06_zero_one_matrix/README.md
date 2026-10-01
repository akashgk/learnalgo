# 01 Matrix

**Difficulty:** Medium | **Category:** Graphs (grid) | **Pattern:** Multi-source BFS (or two-pass DP) | **Source:** LeetCode 542; Grind 75

## The problem

Given a matrix of 0s and 1s, return a matrix where each cell holds the distance (4-directional steps) to the **nearest 0**. There is at least one 0.

```
1 1 1        4 3 2
1 1 1   ->   3 2 1
1 1 0        2 1 0
```

## Step 1: Brute force

BFS from every 1 until a 0 is found: O((mn)^2) in the worst case.

## Step 2: Reverse the direction: start from the zeros

"Distance from each cell to the nearest 0" is the same as "distance from the **set** of zeros to each cell". Put **all zeros** in the queue at distance 0 and run one BFS. BFS visits cells in increasing distance from the source set, so the first time a cell is reached, that distance is final.

This is the same multi-source BFS as Walls and Gates (neetcode 28) and Rotting Oranges (AlgoExpert medium 42).

## Step 3: Alternative: two DP passes

The nearest 0 is reached by a shortest path that, in a grid without walls, can be split into vertical and horizontal moves. Every cell's distance is `min(itself, 1 + neighbor)`. Two sweeps cover all directions:

1. top-left to bottom-right, using the **up** and **left** neighbors;
2. bottom-right to top-left, using the **down** and **right** neighbors.

After both, every cell has its true distance. O(mn) and no queue. (This works because there are no walls; with walls, use BFS.)

## Step 4: The code

<!-- CODE:START -->

Full source: [`zero_one_matrix.dart`](zero_one_matrix.dart) (run it with `dart run`).

```dart
// 01 Matrix: for every cell of a 0/1 matrix, the distance to the nearest 0 (4-directional steps).
// Multi-source BFS from all zeros at once. O(rows * cols) time and space.

import 'dart:collection';

List<List<int>> updateMatrix(List<List<int>> mat) {
  final rows = mat.length, cols = mat[0].length;
  final dist = List.generate(rows, (_) => List<int>.filled(cols, -1)); // -1 = not reached yet
  final queue = Queue<(int, int)>();
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (mat[r][c] == 0) {
        dist[r][c] = 0;
        queue.add((r, c)); // every zero is a source
      }
    }
  }
  while (queue.isNotEmpty) {
    final (r, c) = queue.removeFirst();
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols || dist[nr][nc] != -1) continue;
      dist[nr][nc] = dist[r][c] + 1; // first time reached = nearest zero
      queue.add((nr, nc));
    }
  }
  return dist;
}

/// Alternative: two DP passes (top-left to bottom-right, then the reverse). O(rows * cols), no queue.
List<List<int>> updateMatrixDp(List<List<int>> mat) {
  final rows = mat.length, cols = mat[0].length;
  const big = 1 << 30;
  final d = [
    for (final row in mat) [for (final v in row) v == 0 ? 0 : big],
  ];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (r > 0 && d[r - 1][c] + 1 < d[r][c]) d[r][c] = d[r - 1][c] + 1;
      if (c > 0 && d[r][c - 1] + 1 < d[r][c]) d[r][c] = d[r][c - 1] + 1;
    }
  }
  for (var r = rows - 1; r >= 0; r--) {
    for (var c = cols - 1; c >= 0; c--) {
      if (r < rows - 1 && d[r + 1][c] + 1 < d[r][c]) d[r][c] = d[r + 1][c] + 1;
      if (c < cols - 1 && d[r][c + 1] + 1 < d[r][c]) d[r][c] = d[r][c + 1] + 1;
    }
  }
  return d;
}
```

<!-- CODE:END -->

### Walkthrough of `updateMatrix`

- `dist` starts at -1 (unreached); zeros are set to 0 and enqueued.
- Each neighbor is assigned once, the first time it is reached.

### Walkthrough of `updateMatrixDp`

- Non-zero cells start at a large value.
- The first sweep relaxes from up and left; the second from down and right.

## Step 5: Dry run (BFS)

The 3 x 3 example with a single 0 at (2, 2):

| BFS layer | cells reached |
|---|---|
| 0 | (2, 2) |
| 1 | (1, 2), (2, 1) |
| 2 | (0, 2), (1, 1), (2, 0) |
| 3 | (0, 1), (1, 0) |
| 4 | (0, 0) |

## Complexity

- Time: **O(m * n)** for both methods.
- Space: **O(m * n)** for the output (plus the queue for BFS).

## Edge cases

- All zeros: all distances 0.
- One zero in a corner (the example): distances up to `m + n - 2`.

## Common mistakes

- BFS from each 1 separately (quadratic).
- Only one DP pass (misses zeros that are below or to the right).
- Marking visited on dequeue (cells get enqueued multiple times).

## Follow-ups you should be ready for

1. **Walls in the grid.** The DP shortcut no longer works; BFS still does.
2. **Diagonal moves allowed.** Add the four diagonals in BFS (Chebyshev distance).
3. **Nearest of several kinds of sources.** Multi-source BFS that also records which source reached each cell.

## What to remember

"Distance to the nearest X" for every cell is one BFS started from all X cells at once.
