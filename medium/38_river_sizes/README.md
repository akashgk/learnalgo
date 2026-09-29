# River Sizes

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Connected components on a grid (flood fill)

## The problem

A 2D matrix contains only 0s (land) and 1s (river). A river is a group of 1s connected **horizontally or vertically** (not diagonally). Its size is the number of 1s in it. Return the sizes of all rivers, in any order.

```
[[1, 0, 0, 1, 0],
 [1, 0, 1, 0, 0],
 [0, 0, 1, 0, 1],
 [1, 0, 1, 0, 1],
 [1, 0, 1, 1, 0]]

->  [2, 1, 5, 2, 2]   (any order)
```

## Step 1: See the graph

A grid is an **implicit graph**: each cell is a node, and each cell has edges to its up/down/left/right neighbors. A river is a **connected component** of 1-cells. The question is "find all connected components and their sizes".

## Step 2: The algorithm: flood fill from every unvisited 1

```
for each cell:
    if it is a 1 and not visited:
        explore everything connected to it (DFS or BFS), counting cells and marking them visited
        record the count
```

Each river is discovered exactly once: the first time the scan reaches any of its cells. Marking cells visited ensures later scans skip them.

## Step 3: Implementation choices

- **DFS or BFS?** Either. Only the count matters, not the order.
- **Recursive or iterative?** A recursive DFS on a 1000 x 1000 grid of all 1s needs a million stack frames and will overflow. The iterative version with an explicit stack is safer; mention this.
- **When to mark visited?** When a cell is **pushed**, not when it is popped. Otherwise the same cell can be pushed several times by different neighbors before it is processed.
- **Visited grid or mutate the input?** Setting processed 1s to 0 saves the O(w * h) visited grid, but changes the caller's data. Ask.

## Step 4: The code

<!-- CODE:START -->

Full source: [`river_sizes.dart`](river_sizes.dart) (run it with `dart run`).

```dart
// River Sizes: sizes of connected groups of 1s (4-directional) in a 0/1 matrix.
// Iterative DFS with a visited grid. O(w * h) time and space.

List<int> riverSizes(List<List<int>> matrix) {
  final rows = matrix.length, cols = rows == 0 ? 0 : matrix[0].length;
  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final sizes = <int>[];
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 1 || visited[r][c]) continue;
      var size = 0;
      final stack = [(r, c)];
      visited[r][c] = true;
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        size++;
        for (final (dr, dc) in dirs) {
          final nr = cr + dr, nc = cc + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (matrix[nr][nc] == 1 && !visited[nr][nc]) {
            visited[nr][nc] = true; // mark on push so a cell is never pushed twice
            stack.add((nr, nc));
          }
        }
      }
      sizes.add(size);
    }
  }
  return sizes;
}
```

<!-- CODE:END -->

### Walkthrough

- `visited` is a boolean grid of the same shape.
- `const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];` lists the four directions as records.
- The outer double loop scans every cell; `continue` skips land and visited cells.
- For a new river: push the start cell, mark it, then pop cells, count them, and push unvisited river neighbors (marking them on push).
- Bounds are checked before indexing.

## Step 5: Dry run (the 5-cell river)

The river containing `(1, 2)`: cells `(1,2), (2,2), (3,2), (4,2), (4,3)`.

| pop | size | neighbors pushed |
|---|---|---|
| (1, 2) | 1 | (2, 2) |
| (2, 2) | 2 | (3, 2) |
| (3, 2) | 3 | (4, 2) |
| (4, 2) | 4 | (4, 3) |
| (4, 3) | 5 | none |

Size 5.

## Complexity

- **Time: O(w * h)**: each cell is pushed at most once and examines 4 neighbors.
- **Space: O(w * h)** for `visited` and, in the worst case, the stack.

## Common mistakes

- Including diagonal neighbors.
- Marking visited on pop (duplicates in the stack, wrong counts if you count on push).
- Forgetting bounds checks.

## Follow-ups

1. **Number of Islands (LeetCode #200)** and **Max Area of Island (#695):** the same algorithm; count components or take the max size. Among the most frequently asked graph questions at Google and Amazon.
2. **Number of Islands II (#305):** cells turn into land over time; recomputing is too slow, use Union-Find.
3. **Remove Islands (medium 40)** and **Largest Island (hard 31)** build on this.

## What to remember

Grid = implicit graph. "Groups of connected cells" = connected components = flood fill from every unvisited cell.
