// 01 Matrix: for every cell of a 0/1 matrix, the distance to the nearest 0 (4-directional steps).
// Multi-source BFS from all zeros at once. O(rows * cols) time and space.

import 'dart:collection';

List<List<int>> updateMatrix(List<List<int>> mat) {
  final rows = mat.length, cols = mat[0].length;
  final dist = List.generate(rows, (_) => List<int>.filled(cols, -1)); // -1 = not reached yet
  final queue = Queue<(int, int)>();
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (mat[r][c] == 0) {
        dist[r][c] = 0;
        queue.add((r, c)); // every zero is a source
      }
    }
  }
  while (queue.isNotEmpty) {
    final (r, c) = queue.removeFirst();
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols || dist[nr][nc] != -1) continue;
      dist[nr][nc] = dist[r][c] + 1; // first time reached = nearest zero
      queue.add((nr, nc));
    }
  }
  return dist;
}

/// Alternative: two DP passes (top-left to bottom-right, then the reverse). O(rows * cols), no queue.
List<List<int>> updateMatrixDp(List<List<int>> mat) {
  final rows = mat.length, cols = mat[0].length;
  const big = 1 << 30;
  final d = [
    for (final row in mat) [for (final v in row) v == 0 ? 0 : big],
  ];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (r > 0 && d[r - 1][c] + 1 < d[r][c]) d[r][c] = d[r - 1][c] + 1;
      if (c > 0 && d[r][c - 1] + 1 < d[r][c]) d[r][c] = d[r][c - 1] + 1;
    }
  }
  for (var r = rows - 1; r >= 0; r--) {
    for (var c = cols - 1; c >= 0; c--) {
      if (r < rows - 1 && d[r + 1][c] + 1 < d[r][c]) d[r][c] = d[r + 1][c] + 1;
      if (c < cols - 1 && d[r][c + 1] + 1 < d[r][c]) d[r][c] = d[r][c + 1] + 1;
    }
  }
  return d;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  for (final f in [updateMatrix, updateMatrixDp]) {
    check(
      f([
        [0, 0, 0],
        [0, 1, 0],
        [1, 1, 1],
      ]),
      [
        [0, 0, 0],
        [0, 1, 0],
        [1, 2, 1],
      ],
    );
    check(
      f([
        [1, 1, 1],
        [1, 1, 1],
        [1, 1, 0],
      ]),
      [
        [4, 3, 2],
        [3, 2, 1],
        [2, 1, 0],
      ],
    );
  }
}
