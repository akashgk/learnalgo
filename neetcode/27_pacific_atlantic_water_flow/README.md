# Pacific Atlantic Water Flow

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Reverse the flow: multi-source DFS from the borders | **Source:** LeetCode 417; NeetCode 150, Blind 75

## The problem

An island is a grid of heights. The **Pacific** touches the top and left edges, the **Atlantic** the bottom and right edges. Rain flows from a cell to an adjacent cell (up, down, left, right) whose height is **less than or equal**. Return every cell from which water can reach **both** oceans.

```
  P  P  P  P  P
P 1  2  2  3 (5) A
P 3  2  3 (4)(4) A
P 2  4 (5) 3  1  A
P(6)(7) 1  4  5  A
P(5) 1  1  2  4  A
  A  A  A  A  A
```

Answer: the cells in parentheses.

## Step 1: Brute force

From each cell, run a DFS downhill and check whether it reaches a Pacific edge and an Atlantic edge. O((mn)^2): every cell may explore the whole grid.

## Step 2: Reverse the question

Instead of "where can water from this cell go?", ask "**which cells can reach this ocean?**". Start at the ocean's border cells (they touch the ocean directly) and walk **uphill**: from a cell, move to a neighbor whose height is **greater than or equal**, because water could flow from that neighbor down to here.

One DFS per ocean (starting from all its border cells at once) marks every cell that can drain into it. Each DFS visits each cell at most once: O(mn). The answer is the intersection of the two marked sets.

This "reverse the direction and start from the targets" trick turns many-sources problems into one traversal. Surrounded Regions (AlgoExpert medium 40 Remove Islands) uses the same idea.

## Step 3: The code

<!-- CODE:START -->

Full source: [`pacific_atlantic_water_flow.dart`](pacific_atlantic_water_flow.dart) (run it with `dart run`).

```dart
// Pacific Atlantic Water Flow: water flows from a cell to a neighbor with height <= its own.
// The Pacific touches the top and left edges, the Atlantic the bottom and right edges.
// Return the cells from which water can reach both oceans.
// Reverse the flow: DFS uphill (to neighbors >= current) from each ocean's border cells; answer is
// the intersection of the two reachable sets. O(rows * cols) time and space.

List<List<int>> pacificAtlantic(List<List<int>> heights) {
  final rows = heights.length, cols = heights[0].length;
  final pacific = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final atlantic = List.generate(rows, (_) => List<bool>.filled(cols, false));

  void climb(int r, int c, List<List<bool>> reached) {
    if (reached[r][c]) return;
    reached[r][c] = true;
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
      // Water could flow from (nr, nc) down to (r, c) only if (nr, nc) is at least as high.
      if (heights[nr][nc] >= heights[r][c]) climb(nr, nc, reached);
    }
  }

  for (var c = 0; c < cols; c++) {
    climb(0, c, pacific); // top edge
    climb(rows - 1, c, atlantic); // bottom edge
  }
  for (var r = 0; r < rows; r++) {
    climb(r, 0, pacific); // left edge
    climb(r, cols - 1, atlantic); // right edge
  }
  return [
    for (var r = 0; r < rows; r++)
      for (var c = 0; c < cols; c++)
        if (pacific[r][c] && atlantic[r][c]) [r, c],
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `climb` marks a cell and moves to neighbors at least as high.
- The Pacific DFS starts from the top row and left column; the Atlantic from the bottom row and right column. Corner cells start both.
- The result lists cells in row-major order.

## Step 4: Dry run (one cell)

Cell (2, 2), height 5.

- **Forward view (how rain actually flows):** 5 at (2, 2) -> 3 at (1, 2) -> 2 at (0, 2), which is on the top edge: Pacific. And 5 at (2, 2) -> 3 at (2, 3) -> 1 at (2, 4), which is on the right edge: Atlantic.
- **Reversed view (what the code does):** the Pacific DFS starts at border cell (0, 2) height 2, climbs to (1, 2) height 3, then to (2, 2) height 5. The Atlantic DFS starts at border cell (2, 4) height 1, climbs to (2, 3) height 3, then to (2, 2) height 5. Both mark (2, 2), so it is in the answer.

Cell (1, 2), height 3, is not in the answer: it reaches the Pacific, but its only lower-or-equal neighbors are (0, 2) height 2 and (1, 1) height 2, both of which lead only to the Pacific edges.

## Complexity

- Time: **O(m * n)**.
- Space: **O(m * n)** for the two marked grids and recursion.

## Edge cases

- One cell: it touches both oceans.
- A single row or column: every cell touches both oceans.
- Flat grid: everything drains everywhere.

## Common mistakes

- Climbing with `>` instead of `>=` (water flows to **equal** heights).
- Walking downhill from the borders (the direction must be reversed).
- Running a separate search per cell.

## Follow-ups you should be ready for

1. **Iterative BFS** to avoid deep recursion on large grids.
2. **Surrounded Regions (LeetCode 130).** Mark border-connected cells first; see AlgoExpert medium 40.
3. **Walls and Gates, Rotting Oranges.** Multi-source BFS from all targets at once; see neetcode 28.

## What to remember

When many cells ask "can I reach the target?", start from the target and walk the reversed edges once.
