# Zigzag Traverse

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Anti-diagonal indexing

## The problem

Traverse a 2D array (not necessarily square) in **zigzag** order: start at the top-left, move **down** first, then go diagonally up and to the right until you hit an edge, step along the edge, go diagonally down and to the left, and so on, until the bottom-right. Return the elements in that order.

```
[[ 1,  3,  4, 10],
 [ 2,  5,  9, 11],
 [ 6,  8, 12, 15],
 [ 7, 13, 14, 16]]   ->  [1, 2, 3, ..., 16]
```

## Step 1: The simulation approach and why it is fragile

You can simulate the walk with a direction flag and position, turning at edges:

- going down-left, hitting the left edge: move down; hitting the bottom edge: move right;
- going up-right, hitting the top edge: move right; hitting the right edge: move down.

That is eight edge cases (and corner cases where two edges meet). It works, but it is where most bugs happen under interview pressure.

## Step 2: A cleaner view: anti-diagonals

Label each cell with `d = row + col`:

```
d:  0 1 2 3
    1 2 3 4
    2 3 4 5
    3 4 5 6
```

All cells with the same `d` lie on one **anti-diagonal**. The zigzag visits anti-diagonals in order `d = 0, 1, 2, ...`, and **alternates direction** on each one.

Which direction for which parity? Do not guess; read it from the example. Diagonal 1 is `{(0,1)=3, (1,0)=2}`, and the output visits 2 before 3: **bottom to top** (decreasing row). So odd diagonals go up-right, and even diagonals go down-left (increasing row). Diagonal 2 check: `{(0,2)=4, (1,1)=5, (2,0)=6}`, visited as 4, 5, 6: increasing row. Consistent.

## Step 3: Valid rows on a diagonal

For diagonal `d` in an `rows x cols` matrix, the row `r` must satisfy `0 <= r < rows` and `0 <= d - r < cols`. So:

```
rLo = max(0, d - (cols - 1))
rHi = min(d, rows - 1)
```

Getting these two bounds right is the whole problem. Test on 1xN, Nx1, and non-square matrices.

## Step 4: The code

<!-- CODE:START -->

Full source: [`zigzag_traverse.dart`](zigzag_traverse.dart) (run it with `dart run`).

```dart
// Zigzag Traverse: start top-left, go down, then zigzag along anti-diagonals.
// Iterate diagonals d = r + c; alternate direction per diagonal. O(n) time, O(n) output.

List<int> zigzagTraverse(List<List<int>> array) {
  final out = <int>[];
  if (array.isEmpty) return out;
  final rows = array.length, cols = array[0].length;
  for (var d = 0; d < rows + cols - 1; d++) {
    // Rows on diagonal d range over [rLo, rHi].
    final rLo = d - (cols - 1) > 0 ? d - (cols - 1) : 0;
    final rHi = d < rows - 1 ? d : rows - 1;
    if (d.isEven) {
      // even diagonals go down-left: increasing row
      for (var r = rLo; r <= rHi; r++) {
        out.add(array[r][d - r]);
      }
    } else {
      // odd diagonals go up-right: decreasing row
      for (var r = rHi; r >= rLo; r--) {
        out.add(array[r][d - r]);
      }
    }
  }
  return out;
}
```

<!-- CODE:END -->

### Walkthrough

- `for (var d = 0; d < rows + cols - 1; d++)`: there are `rows + cols - 1` anti-diagonals.
- `rLo` / `rHi` implement the bounds from Step 3.
- Even `d`: rows ascending; odd `d`: rows descending. The column is always `d - r`.

## Step 5: Dry run (4x4 example)

| d | rows | direction | values |
|---|---|---|---|
| 0 | 0..0 | down-left | 1 |
| 1 | 0..1 | up-right (rows 1, 0) | 2, 3 |
| 2 | 0..2 | down-left | 4, 5, 6 |
| 3 | 0..3 | up-right (rows 3..0) | 7, 8, 9, 10 |
| 4 | 1..3 | down-left | 11, 12, 13 |
| 5 | 2..3 | up-right | 14, 15 |
| 6 | 3..3 | down-left | 16 |

## Complexity

- **Time: O(n)**, n = number of cells.
- **Space: O(n)** for the output, O(1) extra.

## Common mistakes

- Assuming the matrix is square (bounds break for rectangles).
- Choosing the direction parity without checking the example (LeetCode's version starts going **up**, which flips it).

## Follow-ups

1. **Diagonal Traverse (LeetCode #498):** same idea, opposite starting direction.
2. **Diagonal Traverse II (#1424):** jagged rows; group cells by `r + c` in buckets.
3. **Spiral Traverse (medium 05):** another boundary-driven matrix walk.

## What to remember

Cells with equal `row + col` form an anti-diagonal; many diagonal traversals become "iterate `d`, compute the valid row range, pick a direction".
