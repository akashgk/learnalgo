# Valid Sudoku

**Difficulty:** Medium | **Category:** Arrays & Hashing | **Pattern:** Hash sets per constraint group | **Source:** LeetCode 36; NeetCode 150

## The problem

Given a partially filled 9 x 9 board (`'.'` for empty), decide whether the filled cells are **consistent**: no digit repeats in any row, any column, or any of the nine 3 x 3 boxes. The board does not need to be solvable.

This is **not** Solve Sudoku (AlgoExpert hard 41). Only the given cells are checked.

## Step 1: Brute force

For each of the 27 groups (9 rows, 9 columns, 9 boxes), collect its digits and check for repeats. That is already O(81 * 3), essentially constant. The interview question is how cleanly you can do it in **one pass**.

## Step 2: One pass, 27 sets

Keep one set per row, per column, and per box. Visit each filled cell once and add its digit to three sets. If any set already contained it, the board is invalid.

The only trick is the **box index**. Rows 0-2 are box row 0, 3-5 are box row 1, 6-8 are box row 2: `r ~/ 3`. Same for columns: `c ~/ 3`. Number the boxes row-major:

```
box = (r ~/ 3) * 3 + c ~/ 3

 0 | 1 | 2
---+---+---
 3 | 4 | 5
---+---+---
 6 | 7 | 8
```

Cell (4, 7): box row 1, box column 2, box `1 * 3 + 2 = 5`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`valid_sudoku.dart`](valid_sudoku.dart) (run it with `dart run`).

```dart
// Valid Sudoku: are the filled cells of a 9 x 9 board consistent (no repeated digit in any row,
// column, or 3 x 3 box)? The board need not be solvable. One pass with 27 sets. O(81) time.

bool isValidSudoku(List<String> board) {
  final rows = List.generate(9, (_) => <String>{});
  final cols = List.generate(9, (_) => <String>{});
  final boxes = List.generate(9, (_) => <String>{});
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final d = board[r][c];
      if (d == '.') continue;
      final b = (r ~/ 3) * 3 + c ~/ 3; // box index 0..8, row-major over boxes
      // Set.add returns false if the digit was already there.
      if (!rows[r].add(d) || !cols[c].add(d) || !boxes[b].add(d)) return false;
    }
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- Three lists of nine sets.
- `continue` skips empty cells.
- `!rows[r].add(d) || !cols[c].add(d) || !boxes[b].add(d)`: `add` returns false on a repeat. Short-circuit evaluation is fine, because we return false on the first conflict anyway.

## Step 4: Dry run

The first invalid test changes the top-left `5` to `8`. Scanning row by row:

| cell | digit | row set | column set | box set | result |
|---|---|---|---|---|---|
| (0, 0) | 8 | row 0: {8} | col 0: {8} | box 0: {8} | ok |
| ... | | | | | |
| (2, 2) | 8 | row 2 | col 2 | box 0 already has 8 | **invalid** |

The box conflict is found at (2, 2), before the column conflict at (3, 0).

## Complexity

- Time: **O(81)**, i.e. O(1) for a fixed board. For an `n x n` board with `sqrt(n)` boxes, O(n^2).
- Space: **O(81)** for the sets.

## Edge cases

- Empty board: valid.
- A digit repeated only within a box (different row and column): caught by the box sets only.

## Common mistakes

- Wrong box index, for example `r ~/ 3 + c ~/ 3` (collides: box (0, 1) and box (1, 0) both give 1).
- Treating `'.'` as a value.
- Trying to solve the board.

## Follow-ups you should be ready for

1. **Bitmasks instead of sets.** One 9-bit integer per group: `mask & (1 << d)` tests, `mask |= 1 << d` adds. Faster and smaller.
2. **Single set of strings.** Insert `"5 in row 0"`, `"5 in col 0"`, `"5 in box 0"`; any failed insert means invalid. Elegant, slower.
3. **Solve the board.** Backtracking with these same sets for O(1) validity checks.

## What to remember

Each constraint group gets its own set. The box index is `(r ~/ 3) * 3 + c ~/ 3`.
