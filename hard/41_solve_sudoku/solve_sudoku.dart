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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final board = [
    [7, 8, 0, 4, 0, 0, 1, 2, 0],
    [6, 0, 0, 0, 7, 5, 0, 0, 9],
    [0, 0, 0, 6, 0, 1, 0, 7, 8],
    [0, 0, 7, 0, 4, 0, 2, 6, 0],
    [0, 0, 1, 0, 5, 0, 9, 3, 0],
    [9, 0, 4, 0, 6, 0, 0, 0, 5],
    [0, 7, 0, 3, 0, 0, 0, 1, 2],
    [1, 2, 0, 0, 0, 7, 4, 0, 0],
    [0, 4, 9, 2, 0, 6, 0, 0, 7],
  ];
  final solved = solveSudoku(board);
  check(isValidSolution(solved), true);
  check(solved[0], [7, 8, 5, 4, 3, 9, 1, 2, 6]);
}
