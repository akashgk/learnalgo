// Word Search: does the word exist in the grid as a path of horizontally/vertically adjacent
// cells, using each cell at most once? DFS backtracking from every cell.
// O(rows * cols * 3^L) time where L = word length, O(L) recursion space.

bool exist(List<List<String>> board, String word) {
  final rows = board.length, cols = board[0].length;
  bool dfs(int r, int c, int i) {
    if (i == word.length) return true;
    if (r < 0 || c < 0 || r >= rows || c >= cols || board[r][c] != word[i]) return false;
    final saved = board[r][c];
    board[r][c] = '#'; // mark visited in place instead of a separate visited set
    final found = dfs(r + 1, c, i + 1) || dfs(r - 1, c, i + 1) || dfs(r, c + 1, i + 1) || dfs(r, c - 1, i + 1);
    board[r][c] = saved; // backtrack: restore for other paths
    return found;
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (dfs(r, c, 0)) return true;
    }
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  List<List<String>> board() => [
    ['A', 'B', 'C', 'E'],
    ['S', 'F', 'C', 'S'],
    ['A', 'D', 'E', 'E'],
  ];
  check(exist(board(), 'ABCCED'), true);
  check(exist(board(), 'SEE'), true);
  check(exist(board(), 'ABCB'), false); // would reuse the B
  check(exist(board(), 'ASADFBCCEESE'), true); // snakes through the grid
  check(
    exist([
      ['a'],
    ], 'a'),
    true,
  );
  check(
    exist([
      ['a', 'a'],
    ], 'aaa'),
    false,
  );
}
