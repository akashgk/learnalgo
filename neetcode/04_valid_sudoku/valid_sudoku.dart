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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final valid = [
    '53..7....',
    '6..195...',
    '.98....6.',
    '8...6...3',
    '4..8.3..1',
    '7...2...6',
    '.6....28.',
    '...419..5',
    '....8..79',
  ];
  check(isValidSudoku(valid), true);
  // Same board with the top-left 5 changed to 8: column 0 now has two 8s (and the box too).
  check(isValidSudoku(['83..7....', ...valid.skip(1)]), false);
  // Box conflict only: 9 at (0, 0) and 9 at (2, 2), different rows and columns.
  check(isValidSudoku(['9........', '.........', '..9......', ...List.filled(6, '.........')]), false);
  check(isValidSudoku(List.filled(9, '.........')), true);
}
