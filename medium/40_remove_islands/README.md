# Remove Islands

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Flood fill from the boundary (reverse the question)

## The problem

A matrix contains 0s (white) and 1s (black). An **island** is a group of horizontally/vertically connected 1s that does **not** touch the border of the matrix. Any 1 that is on the border, or connected to a border 1, is not part of an island. Replace every island's 1s with 0s and return the matrix.

```
input                        output
1 0 0 0 0 0                  1 0 0 0 0 0
0 1 0 1 1 1                  0 0 0 1 1 1
0 0 1 0 1 0        ->        0 0 0 0 1 0
1 1 0 0 1 0                  1 1 0 0 1 0
1 0 1 1 0 0                  1 0 0 0 0 0
1 0 0 0 0 1                  1 0 0 0 0 1
```

## Step 1: The direct approach and its problem

Flood-fill each group of 1s; if no cell in the group touches the border, erase the group. You only know whether a group is an island **after** exploring all of it, so you must store the group's cells first and then decide. It works, but it is clumsy.

## Step 2: Reverse the question

Instead of finding islands, find what is **not** an island: every 1 reachable from a 1 on the border. Everything else that is a 1 must be an island.

1. For every 1 on the border, flood-fill its connected region and mark those cells as **safe** (here: change them to 2).
2. Final pass over the matrix: `2 -> 1` (safe, restore it), `1 -> 0` (never reached from the border, so it is an island).

No group storage and no after-the-fact decisions.

## Step 3: The code

<!-- CODE:START -->

Full source: [`remove_islands.dart`](remove_islands.dart) (run it with `dart run`).

```dart
// Remove Islands: 1s not connected (4-directionally) to the border become 0.
// Flood-fill from border 1s, marking them as 2, then convert: 1 -> 0, 2 -> 1.
// O(w * h) time and space (stack).

List<List<int>> removeIslands(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

  void markConnectedToBorder(int r, int c) {
    final stack = [(r, c)];
    while (stack.isNotEmpty) {
      final (cr, cc) = stack.removeLast();
      if (cr < 0 || cr >= rows || cc < 0 || cc >= cols || matrix[cr][cc] != 1) continue;
      matrix[cr][cc] = 2;
      for (final (dr, dc) in dirs) {
        stack.add((cr + dr, cc + dc));
      }
    }
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final onBorder = r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
      if (onBorder && matrix[r][c] == 1) markConnectedToBorder(r, c);
    }
  }
  for (final row in matrix) {
    for (var c = 0; c < cols; c++) {
      row[c] = row[c] == 2 ? 1 : 0;
    }
  }
  return matrix;
}
```

<!-- CODE:END -->

### Walkthrough

- `markConnectedToBorder(r, c)` is an iterative DFS. It pushes coordinates freely and filters when popping: out of bounds, or not a 1 (0 or already marked 2), is skipped. This style is simple, at the cost of pushing some cells that get discarded.
- The double loop calls it only for border cells (`r == 0 || c == 0 || r == rows - 1 || c == cols - 1`) that contain a 1.
- The final loop maps 2 to 1 and everything else to 0.

## Step 4: Dry run (key cells)

- Border cell `(1, 5)` is 1: its region `(1,3), (1,4), (1,5), (2,4), (3,4)` becomes 2.
- Border cells `(3,0), (4,0), (5,0)` and `(3,1)` connected to them become 2.
- `(0,0)` and `(5,5)` are border 1s: 2.
- `(1,1), (2,2), (4,2), (4,3)` are never reached from the border: they stay 1 and become 0 in the final pass.

## Complexity

- **Time: O(w * h)**: every cell is processed a constant number of times.
- **Space: O(w * h)** in the worst case for the DFS stack.

## Common mistakes

- Treating diagonal connections as connected.
- Forgetting the corners or one of the four borders in the border scan.
- Using a separate visited grid is fine; forgetting to mark at all causes infinite loops.

## Follow-ups

1. **Surrounded Regions (LeetCode #130):** identical with `'X'`/`'O'`.
2. **Pacific Atlantic Water Flow (#417):** flood from each ocean's border "uphill", then intersect the two reachable sets.
3. **Number of Enclaves (#1020):** count island cells instead of removing them.

## What to remember

When the condition is "not connected to the boundary", flood-fill from the boundary and treat everything unreached as the answer.
