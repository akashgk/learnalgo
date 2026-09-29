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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    revealMinesweeper(
      [
        ['M', 'M'],
        ['H', 'H'],
        ['H', 'H'],
      ],
      2,
      0,
    ),
    [
      ['M', 'M'],
      ['2', '2'],
      ['0', '0'],
    ],
  );
  check(
    revealMinesweeper(
      [
        ['H', 'H', 'H', 'H', 'M'],
        ['H', '1', 'M', 'H', '1'],
        ['H', 'H', 'H', 'H', 'H'],
        ['H', 'H', 'H', 'H', 'H'],
      ],
      3,
      4,
    ),
    [
      ['0', '1', 'H', 'H', 'M'],
      ['0', '1', 'M', '2', '1'],
      ['0', '1', '1', '1', '0'],
      ['0', '0', '0', '0', '0'],
    ],
  );
  check(
    revealMinesweeper(
      [
        ['M'],
      ],
      0,
      0,
    ),
    [
      ['X'],
    ],
  );
}
