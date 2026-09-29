# Solve Sudoku

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Constraint backtracking with O(1) validity checks

## The problem

Solve a 9x9 Sudoku puzzle in place. Empty cells are 0. Every row, every column, and every 3x3 box must contain the digits 1 through 9 exactly once. The puzzle has exactly one solution.

## Step 1: Backtracking

Take the empty cells in some order. For the current cell:

1. try each digit 1..9 that does not conflict with its row, column, or box;
2. place it and recurse to the next empty cell;
3. if the recursion fails, **undo** the placement and try the next digit;
4. if no digit works, return failure to the previous cell.

When every empty cell is filled, the puzzle is solved.

This is the same choose / explore / un-choose template as Permutations and N-Queens.

## Step 2: Make "is this digit allowed?" O(1)

The naive check scans the row, column, and box: 27 cells per attempt. Instead, keep three arrays of "used digits":

- `rows[r]`: digits already used in row r,
- `cols[c]`: digits used in column c,
- `boxes[b]`: digits used in box b, where `b = (r ~/ 3) * 3 + c ~/ 3`.

Represent each as a **bitmask**: bit `d` is set if digit `d` is used. Then:

- all digits blocked for a cell: `rows[r] | cols[c] | boxes[b]` (one OR);
- check digit d: `used & (1 << d) != 0`;
- place: set the bit in all three; undo: clear it (XOR).

## Step 3: A heuristic worth mentioning

**Minimum remaining values (MRV):** always fill next the empty cell with the **fewest** allowed digits. A cell with one option is forced; a cell with zero options means backtrack immediately. This prunes the search tree dramatically on hard puzzles. The code fills cells in reading order for simplicity; MRV is a natural extension.

## Step 4: The code

<!-- CODE:START -->

Full source: [`solve_sudoku.dart`](solve_sudoku.dart) (run it with `dart run`).

```dart
// Solve Sudoku (9x9, 0 = empty). Backtracking with row/column/box bitmasks for O(1) validity.
// Worst case exponential; fast in practice. Mutates and returns the board.

List<List<int>> solveSudoku(List<List<int>> board) {
  final rows = List<int>.filled(9, 0), cols = List<int>.filled(9, 0), boxes = List<int>.filled(9, 0);
  final empty = <(int, int)>[];
  int box(int r, int c) => (r ~/ 3) * 3 + c ~/ 3;
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final v = board[r][c];
      if (v == 0) {
        empty.add((r, c));
      } else {
        final bit = 1 << v;
        rows[r] |= bit;
        cols[c] |= bit;
        boxes[box(r, c)] |= bit;
      }
    }
  }

  bool solve(int idx) {
    if (idx == empty.length) return true;
    final (r, c) = empty[idx];
    final b = box(r, c);
    final used = rows[r] | cols[c] | boxes[b];
    for (var v = 1; v <= 9; v++) {
      final bit = 1 << v;
      if (used & bit != 0) continue;
      board[r][c] = v;
      rows[r] |= bit;
      cols[c] |= bit;
      boxes[b] |= bit;
      if (solve(idx + 1)) return true;
      rows[r] ^= bit; // undo
      cols[c] ^= bit;
      boxes[b] ^= bit;
    }
    board[r][c] = 0;
    return false;
  }

  solve(0);
  return board;
}

bool isValidSolution(List<List<int>> b) {
  for (var i = 0; i < 9; i++) {
    final row = <int>{}, col = <int>{}, box = <int>{};
    for (var j = 0; j < 9; j++) {
      row.add(b[i][j]);
      col.add(b[j][i]);
      box.add(b[(i ~/ 3) * 3 + j ~/ 3][(i % 3) * 3 + j % 3]);
    }
    if (row.length != 9 || col.length != 9 || box.length != 9 || row.contains(0)) return false;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- The first double loop records given digits in the masks and collects the list of empty cells.
- `solve(idx)` handles the `idx`-th empty cell:
  - `used` combines the three masks;
  - for each free digit, place it, update masks, recurse;
  - on failure, undo with XOR and try the next digit;
  - if all fail, reset the cell to 0 and return false.
- `isValidSolution` (test helper) independently checks every row, column, and box.

## Complexity

- **Time:** exponential in the worst case (up to 9^m for m empty cells), but constraint pruning makes real puzzles solve in milliseconds.
- **Space: O(m)** recursion depth (at most 81) plus the fixed-size masks.

## Common mistakes

- Forgetting to undo the masks when backtracking.
- Wrong box index formula (use `(r ~/ 3) * 3 + c ~/ 3`).
- Re-scanning the board for every check (correct but slow).

## Follow-ups

1. **Sudoku Solver (LeetCode #37)** and **Valid Sudoku (#36):** the validation part alone uses the same masks.
2. **Exact cover:** Sudoku is an exact cover problem; Knuth's Algorithm X with Dancing Links is the famous general technique (naming it is enough).
3. **N-Queens:** see Non-Attacking Queens (very hard 30), which uses the same bitmask idea for columns and diagonals.

## What to remember

Backtracking plus constant-time constraint checks (bitmasks per row, column, and box). Undo exactly what you did before trying the next option.
