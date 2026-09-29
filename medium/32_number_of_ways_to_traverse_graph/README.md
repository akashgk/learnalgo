# Number Of Ways To Traverse Graph

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Grid DP / combinatorics

## The problem

A grid has `width` columns and `height` rows. Starting at the top-left cell, you want to reach the bottom-right cell, moving only **right** or **down**. Return the number of distinct paths.

```
width = 4, height = 3  ->  10
```

## Step 1: Work an example by hand

Write in each cell the number of ways to reach it:

```
1   1   1   1
1   2   3   4
1   3   6  10
```

- Every cell in the top row can only be reached by going right: 1 way.
- Every cell in the left column: only by going down: 1 way.
- Any other cell is entered either from above or from the left. So its count is the sum of those two cells.

## Step 2: Brute force

Recursively try both moves from every cell. The number of paths itself grows exponentially, so enumerating them is exponential.

## Step 3: DP

`ways[r][c] = ways[r-1][c] + ways[r][c-1]`, with the first row and column equal to 1. Fill row by row: O(w * h).

**Space optimization:** each row only needs the row above. Keep one row and update it in place from left to right: when you compute `row[c]`, `row[c]` still holds the value from the row above ("from above") and `row[c-1]` already holds the current row's value ("from the left"). So `row[c] += row[c-1]`.

## Step 4: Math

Every path consists of exactly `w - 1` right moves and `h - 1` down moves, in some order. A path is determined by choosing **which** of the `w + h - 2` moves are "right":

```
paths = C(w + h - 2, w - 1)
```

For w = 4, h = 3: `C(5, 3) = 10`.

Compute it incrementally to avoid huge factorials: `result = result * (n - k + i) / i` for `i = 1..k`. Multiplying before dividing keeps every intermediate value an exact integer (each intermediate is itself a binomial coefficient).

## Step 5: The code

<!-- CODE:START -->

Full source: [`number_of_ways_to_traverse_graph.dart`](number_of_ways_to_traverse_graph.dart) (run it with `dart run`).

```dart
// Number Of Ways To Traverse Graph: moves only right or down in a width x height grid.
// DP: ways[r][c] = ways[r-1][c] + ways[r][c-1]; rolling row. O(w * h) time, O(w) space.
// Combinatorics alternative: C((w-1) + (h-1), w-1).

int numberOfWaysToTraverseGraph(int width, int height) {
  final row = List<int>.filled(width, 1); // first row: one way to each cell
  for (var r = 1; r < height; r++) {
    for (var c = 1; c < width; c++) {
      row[c] += row[c - 1]; // from above (old row[c]) + from left (row[c-1])
    }
  }
  return row[width - 1];
}

int numberOfWaysMath(int width, int height) {
  // C(n, k) computed incrementally; each intermediate value is an exact integer.
  final n = width + height - 2, k = width - 1 < height - 1 ? width - 1 : height - 1;
  var result = 1;
  for (var i = 1; i <= k; i++) {
    result = result * (n - k + i) ~/ i;
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough of `numberOfWaysToTraverseGraph`

- `final row = List<int>.filled(width, 1);` is the first row.
- For each later row, `row[c] += row[c - 1]` for `c >= 1` (`row[0]` stays 1: the left column).
- The answer is the last cell.

### Walkthrough of `numberOfWaysMath`

- `n = width + height - 2` total moves, `k = min(width - 1, height - 1)` (using the smaller k means fewer iterations; `C(n, k) = C(n, n - k)`).
- `result = result * (n - k + i) ~/ i;` builds `C(n - k + i, i)` step by step.

## Step 6: Dry run (DP, width 4, height 3)

| row | values |
|---|---|
| 0 | 1 1 1 1 |
| 1 | 1 2 3 4 |
| 2 | 1 3 6 **10** |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Recursion | exponential | O(w + h) |
| DP table | O(w * h) | O(w * h) |
| Rolling row | O(w * h) | O(w) |
| Binomial coefficient | O(min(w, h)) | O(1) |

## Common mistakes

- Mixing up width/height and rows/columns.
- Computing factorials directly (overflow even for moderate sizes).

## Follow-ups

1. **Unique Paths (LeetCode #62):** identical.
2. **Unique Paths II (#63):** obstacles. Set `ways = 0` on blocked cells. The formula no longer applies, but the DP does. This is why you should know both.
3. **Minimum Path Sum (#64):** each cell has a cost; replace `+` with `min` of the two neighbors plus the cell's cost.

## What to remember

Grid path counting: each cell = sum of the cells it can be entered from. When moves are unconstrained, it is also a binomial coefficient.
