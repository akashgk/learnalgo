# Reveal Minesweeper

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Flood fill with a stopping condition

## The problem

A Minesweeper board contains:

- `'M'`: a hidden mine,
- `'H'`: a hidden safe cell,
- digits `'0'` to `'8'`: already revealed cells (the number of adjacent mines).

Given the cell the player clicks:

- If it is a mine, replace it with `'X'` and return the board.
- Otherwise reveal it: write the number of mines among its **8** neighbors. If that number is 0, also reveal every hidden neighbor by the same rules (this can cascade).

```
click (2, 0):
M M          M M
H H    ->    2 2
H H          0 0
```

## Step 1: Work an example by hand

Click (2, 0). Its neighbors are (1, 0), (1, 1), (2, 1): no mines. So write `0`, and reveal those neighbors:

- (1, 0): neighbors include (0, 0) and (0, 1), both mines: write `2`. Not zero, so it does **not** spread.
- (1, 1): also 2 mines adjacent: `2`.
- (2, 1): no mines adjacent: `0`, spreads to its hidden neighbors (all already revealed).

Result: the rows `2 2` and `0 0`.

## Step 2: The algorithm

This is flood fill (like River Sizes), with one difference: the fill **stops** at cells that have at least one adjacent mine. Those cells are revealed but do not spread.

```
reveal(cell):
    if cell is not hidden ('H'): return          # already revealed
    count mines among the 8 neighbors
    write the count
    if count == 0: reveal each hidden neighbor
```

## Step 3: Implementation details

- **8 neighbors**, not 4. Generate them with `dr, dc in {-1, 0, 1}` excluding `(0, 0)`, with bounds checks.
- **The board is the visited set:** only process cells that are still `'H'`. A revealed cell is never processed twice.
- **Iterative stack** instead of recursion: a huge empty board would otherwise recurse very deeply.

## Step 4: The code

<!-- CODE:START -->

Full source: [`reveal_minesweeper.dart`](reveal_minesweeper.dart) (run it with `dart run`).

```dart
// Reveal Minesweeper. Board cells: 'M' mine, 'H' hidden, or a revealed digit '0'..'8'.
// Clicking a mine turns it into 'X'. Otherwise reveal the adjacent-mine count; if it is 0,
// reveal neighbors recursively (iterative flood fill). O(w * h) time and space.

List<List<String>> revealMinesweeper(List<List<String>> board, int row, int column) {
  if (board[row][column] == 'M') {
    board[row][column] = 'X';
    return board;
  }
  final rows = board.length, cols = board[0].length;
  Iterable<(int, int)> neighbors(int r, int c) sync* {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nr = r + dr, nc = c + dc;
        if ((dr != 0 || dc != 0) && nr >= 0 && nr < rows && nc >= 0 && nc < cols) yield (nr, nc);
      }
    }
  }

  final stack = [(row, column)];
  while (stack.isNotEmpty) {
    final (r, c) = stack.removeLast();
    if (board[r][c] != 'H') continue; // already revealed
    final around = neighbors(r, c).toList();
    final mines = around.where((p) => board[p.$1][p.$2] == 'M').length;
    board[r][c] = '$mines';
    if (mines == 0) {
      stack.addAll(around.where((p) => board[p.$1][p.$2] == 'H'));
    }
  }
  return board;
}
```

<!-- CODE:END -->

### Walkthrough

- The first `if` handles clicking a mine.
- `neighbors(r, c)` is a `sync*` generator that lazily yields valid neighbor coordinates.
- The loop pops a cell, skips it if it is no longer hidden, counts adjacent mines (`p.$1`, `p.$2` access record fields), writes the count as a string, and pushes hidden neighbors when the count is 0.

## Complexity

- **Time: O(w * h)**: each cell is revealed at most once and checks 8 neighbors.
- **Space: O(w * h)** for the stack in the worst case.

## Common mistakes

- Using only 4 neighbors.
- Spreading from cells whose count is non-zero.
- Revealing mines during the cascade (only `'H'` cells are ever pushed, and a zero-count cell has no mine neighbors anyway).

## Follow-ups

1. **Minesweeper (LeetCode #529):** the same rules with slightly different symbols.
2. **Design question:** generate a random board with m mines (Fisher-Yates shuffle of cell indices), guarantee the first click is safe (place mines after the first click), and count neighbors efficiently. Common object-oriented design follow-up.

## What to remember

Flood fill can have a stopping rule: reveal the boundary cells, but only spread from cells that meet the spreading condition.
