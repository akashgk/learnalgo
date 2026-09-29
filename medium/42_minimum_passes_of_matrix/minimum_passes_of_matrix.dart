// Minimum Passes Of Matrix: each pass, negatives adjacent to a positive flip positive.
// Multi-source BFS level by level from all positives. Return -1 if some negative stays.
// O(w * h) time and space.

import 'dart:collection';

int minimumPassesOfMatrix(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  var queue = Queue<(int, int)>();
  var negatives = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] > 0) queue.add((r, c));
      if (matrix[r][c] < 0) negatives++;
    }
  }
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  var passes = 0;
  while (queue.isNotEmpty && negatives > 0) {
    final next = Queue<(int, int)>();
    for (final (r, c) in queue) {
      for (final (dr, dc) in dirs) {
        final nr = r + dr, nc = c + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols || matrix[nr][nc] >= 0) continue;
        matrix[nr][nc] *= -1;
        negatives--;
        next.add((nr, nc));
      }
    }
    queue = next;
    passes++;
  }
  return negatives == 0 ? passes : -1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    minimumPassesOfMatrix([
      [0, -1, -3, 2, 0],
      [1, -2, -5, -1, -3],
      [3, 0, 0, -4, -1],
    ]),
    3,
  );
  check(
    minimumPassesOfMatrix([
      [1, 0, -1],
    ]),
    -1,
  ); // 0 blocks the spread
  check(
    minimumPassesOfMatrix([
      [1, 2],
    ]),
    0,
  );
}
