// Cherry Pickup II: two robots start at the top-left and top-right corners and move down one row
// per step (column -1, 0, or +1). Each collects the cherries of the cells it visits; a cell shared
// by both counts once. Maximize the total.
// DP over (row, col1, col2), both robots moving together. O(rows * cols^2 * 9) time, O(cols^2) space.

int cherryPickup(List<List<int>> grid) {
  final rows = grid.length, cols = grid[0].length;
  const neg = -1 << 40; // unreachable state
  // dp[c1][c2]: best total with robot 1 at column c1 and robot 2 at c2 in the current row.
  var dp = List.generate(cols, (_) => List<int>.filled(cols, neg));
  dp[0][cols - 1] = grid[0][0] + (cols > 1 ? grid[0][cols - 1] : 0);
  for (var r = 1; r < rows; r++) {
    final next = List.generate(cols, (_) => List<int>.filled(cols, neg));
    for (var c1 = 0; c1 < cols; c1++) {
      for (var c2 = 0; c2 < cols; c2++) {
        if (dp[c1][c2] == neg) continue;
        for (var d1 = -1; d1 <= 1; d1++) {
          for (var d2 = -1; d2 <= 1; d2++) {
            final n1 = c1 + d1, n2 = c2 + d2;
            if (n1 < 0 || n2 < 0 || n1 >= cols || n2 >= cols) continue;
            final gain = grid[r][n1] + (n1 == n2 ? 0 : grid[r][n2]);
            if (dp[c1][c2] + gain > next[n1][n2]) next[n1][n2] = dp[c1][c2] + gain;
          }
        }
      }
    }
    dp = next;
  }
  var best = 0;
  for (final row in dp) {
    for (final v in row) {
      if (v > best) best = v;
    }
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    cherryPickup([
      [3, 1, 1],
      [2, 5, 1],
      [1, 5, 5],
      [2, 1, 1],
    ]),
    24,
  );
  check(
    cherryPickup([
      [1, 0, 0, 0, 0, 0, 1],
      [2, 0, 0, 0, 0, 3, 0],
      [2, 0, 9, 0, 0, 0, 0],
      [0, 3, 0, 5, 4, 0, 0],
      [1, 0, 2, 3, 0, 0, 6],
    ]),
    28,
  );
  check(
    cherryPickup([
      [1, 1],
      [1, 1],
    ]),
    4,
  );
  check(
    cherryPickup([
      [5],
      [7],
    ]),
    12,
  ); // one column: both robots share every cell
}
