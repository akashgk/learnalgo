// River Sizes: sizes of connected groups of 1s (4-directional) in a 0/1 matrix.
// Iterative DFS with a visited grid. O(w * h) time and space.

List<int> riverSizes(List<List<int>> matrix) {
  final rows = matrix.length, cols = rows == 0 ? 0 : matrix[0].length;
  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final sizes = <int>[];
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 1 || visited[r][c]) continue;
      var size = 0;
      final stack = [(r, c)];
      visited[r][c] = true;
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        size++;
        for (final (dr, dc) in dirs) {
          final nr = cr + dr, nc = cc + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (matrix[nr][nc] == 1 && !visited[nr][nc]) {
            visited[nr][nc] = true; // mark on push so a cell is never pushed twice
            stack.add((nr, nc));
          }
        }
      }
      sizes.add(size);
    }
  }
  return sizes;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final m = [
    [1, 0, 0, 1, 0],
    [1, 0, 1, 0, 0],
    [0, 0, 1, 0, 1],
    [1, 0, 1, 0, 1],
    [1, 0, 1, 1, 0],
  ];
  check(riverSizes(m)..sort(), [1, 2, 2, 2, 5]);
  check(
    riverSizes([
      [0],
    ]),
    [],
  );
}
