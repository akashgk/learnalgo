# Non-Attacking Queens

**Difficulty:** Very Hard | **Category:** Recursion | **Pattern:** Backtracking with O(1) conflict checks (bitmasks)

## The problem

Return the number of ways to place n queens on an n x n chessboard so that no two queens attack each other (no two share a row, a column, or a diagonal).

```
n = 4  ->  2
n = 8  ->  92
```

The two solutions for n = 4 (columns of the queens, row by row): `[1, 3, 0, 2]` and `[2, 0, 3, 1]`.

## Step 1: Reduce the search space

- Placing n queens anywhere on n^2 squares: astronomically many options.
- Every **row** must contain exactly one queen: place them row by row, choosing a column each time: n^n options.
- Every **column** must also contain exactly one: at most n! options (permutations).

## Step 2: Backtracking

```
place(row):
    if row == n: count one solution
    for each column that is safe in this row:
        place a queen there; mark its column and diagonals
        place(row + 1)
        remove the queen; unmark
```

Branches die as soon as a row has no safe column, which prunes the search enormously: for n = 8 the search tree has 2,057 nodes, versus 40,320 permutations.

## Step 3: O(1) safety checks

A queen at `(row, col)` blocks:

- its column,
- its "down-right" diagonal, on which `row - col` is constant,
- its "down-left" diagonal, on which `row + col` is constant.

Keep three sets (or boolean arrays): used columns, used `row - col` values, used `row + col` values. A square is safe iff none of its three values is used.

## Step 4: Bitmasks (this code)

Represent the three sets for the **current row** as bitmasks with one bit per column:

- `cols`: columns already used;
- `diag`: columns attacked along one diagonal direction;
- `antiDiag`: columns attacked along the other.

Free columns in this row: `full & ~(cols | diag | antiDiag)`. Moving to the next row, diagonal attacks shift by one column: `diag` shifts left, `antiDiag` shifts right. `free & -free` isolates the lowest free column, so the loop iterates only over free columns.

## Step 5: The code

<!-- CODE:START -->

Full source: [`non_attacking_queens.dart`](non_attacking_queens.dart) (run it with `dart run`).

```dart
// Non-Attacking Queens: number of ways to place n queens on an n x n board with no attacks.
// Backtracking row by row with bitmasks for columns and both diagonals.
// O(n!) time (pruned heavily), O(n) space.

int nonAttackingQueens(int n) {
  final full = (1 << n) - 1;
  int place(int cols, int diag, int antiDiag) {
    if (cols == full) return 1;
    var count = 0;
    // Free positions in this row: not attacked by column or either diagonal.
    var free = full & ~(cols | diag | antiDiag);
    while (free != 0) {
      final bit = free & -free; // lowest free column
      free -= bit;
      // Diagonals shift by one column per row moved down.
      count += place(cols | bit, ((diag | bit) << 1) & full, (antiDiag | bit) >> 1);
    }
    return count;
  }

  return place(0, 0, 0);
}
```

<!-- CODE:END -->

### Walkthrough

- `full = (1 << n) - 1` has one bit per column.
- `if (cols == full) return 1;` means every column is used: n queens placed.
- The `while (free != 0)` loop tries each free column: `bit = free & -free`, then removes it from `free`.
- The recursive call passes the updated column mask and the shifted diagonal masks (masked with `full` so bits do not leave the board).

## Step 6: Known answers (the test checks these)

| n | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| solutions | 1 | 0 | 0 | 2 | 10 | 4 | 40 | 92 | 352 |

## Complexity

- **Time: O(n!)** as an upper bound; pruning makes the real number of explored placements far smaller.
- **Space: O(n)** recursion depth.

## Common mistakes

- Checking diagonals by scanning the board (O(n) per check).
- Forgetting one of the two diagonal directions.
- Not undoing the markers (with the bitmask version, the undo is automatic because masks are passed by value).

## Follow-ups

1. **N-Queens (LeetCode #51):** return the boards; keep the chosen column per row.
2. **N-Queens II (#52):** the count, as here.
3. **Solve Sudoku (hard 41):** the same backtracking with constraint masks.

## What to remember

Backtracking row by row, with constant-time conflict checks for columns and both diagonals (`row - col` and `row + col`, or shifting bitmasks).
