// Longest Increasing Path in a Matrix: longest path moving up/down/left/right to strictly larger
// values. Strictly increasing moves can never cycle, so the "longest path from cell" values form a
// DAG DP: memoized DFS. O(rows * cols) time and space.

int longestIncreasingPath(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  final memo = List.generate(rows, (_) => List<int>.filled(cols, 0)); // 0 = not computed yet
  int longestFrom(int r, int c) {
    if (memo[r][c] != 0) return memo[r][c];
    var best = 1; // the cell alone
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
      if (matrix[nr][nc] > matrix[r][c]) {
        final len = 1 + longestFrom(nr, nc);
        if (len > best) best = len;
      }
    }
    return memo[r][c] = best;
  }

  var answer = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final len = longestFrom(r, c);
      if (len > answer) answer = len;
    }
  }
  return answer;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    longestIncreasingPath([
      [9, 9, 4],
      [6, 6, 8],
      [2, 1, 1],
    ]),
    4,
  ); // 1 2 6 9
  check(
    longestIncreasingPath([
      [3, 4, 5],
      [3, 2, 6],
      [2, 2, 1],
    ]),
    4,
  ); // 3 4 5 6
  check(
    longestIncreasingPath([
      [1],
    ]),
    1,
  );
  check(
    longestIncreasingPath([
      [7, 7],
      [7, 7],
    ]),
    1,
  ); // equal values do not count
}
