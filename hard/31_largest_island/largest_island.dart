// Largest Island: 0 = land, 1 = water (AlgoExpert's convention). You may turn one water cell
// into land. Return the largest island size achievable (4-directional adjacency).
// Label each island with an id and size, then try each water cell. O(w * h) time and space.

int largestIsland(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  final islandId = List.generate(rows, (_) => List<int>.filled(cols, -1));
  final sizes = <int>[];

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 0 || islandId[r][c] != -1) continue;
      final id = sizes.length;
      var size = 0;
      final stack = [(r, c)];
      islandId[r][c] = id;
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        size++;
        for (final (dr, dc) in dirs) {
          final nr = cr + dr, nc = cc + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (matrix[nr][nc] == 0 && islandId[nr][nc] == -1) {
            islandId[nr][nc] = id;
            stack.add((nr, nc));
          }
        }
      }
      sizes.add(size);
    }
  }

  var best = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a > b ? a : b);
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 1) continue;
      final touching = <int>{}; // distinct islands around this water cell
      for (final (dr, dc) in dirs) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && islandId[nr][nc] != -1) {
          touching.add(islandId[nr][nc]);
        }
      }
      final size = 1 + touching.fold<int>(0, (s, id) => s + sizes[id]);
      if (size > best) best = size;
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
    largestIsland([
      [0, 1, 1],
      [0, 0, 1],
      [1, 1, 0],
    ]),
    5,
  );
  check(
    largestIsland([
      [1, 1],
      [1, 1],
    ]),
    1,
  );
  check(
    largestIsland([
      [0, 0],
      [0, 0],
    ]),
    4,
  );
  check(
    largestIsland([
      [0, 1, 0],
    ]),
    3,
  );
}
