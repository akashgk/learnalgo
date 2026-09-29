// Remove Islands: 1s not connected (4-directionally) to the border become 0.
// Flood-fill from border 1s, marking them as 2, then convert: 1 -> 0, 2 -> 1.
// O(w * h) time and space (stack).

List<List<int>> removeIslands(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

  void markConnectedToBorder(int r, int c) {
    final stack = [(r, c)];
    while (stack.isNotEmpty) {
      final (cr, cc) = stack.removeLast();
      if (cr < 0 || cr >= rows || cc < 0 || cc >= cols || matrix[cr][cc] != 1) continue;
      matrix[cr][cc] = 2;
      for (final (dr, dc) in dirs) {
        stack.add((cr + dr, cc + dc));
      }
    }
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final onBorder = r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
      if (onBorder && matrix[r][c] == 1) markConnectedToBorder(r, c);
    }
  }
  for (final row in matrix) {
    for (var c = 0; c < cols; c++) {
      row[c] = row[c] == 2 ? 1 : 0;
    }
  }
  return matrix;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    removeIslands([
      [1, 0, 0, 0, 0, 0],
      [0, 1, 0, 1, 1, 1],
      [0, 0, 1, 0, 1, 0],
      [1, 1, 0, 0, 1, 0],
      [1, 0, 1, 1, 0, 0],
      [1, 0, 0, 0, 0, 1],
    ]),
    [
      [1, 0, 0, 0, 0, 0],
      [0, 0, 0, 1, 1, 1],
      [0, 0, 0, 0, 1, 0],
      [1, 1, 0, 0, 1, 0],
      [1, 0, 0, 0, 0, 0],
      [1, 0, 0, 0, 0, 1],
    ],
  );
}
