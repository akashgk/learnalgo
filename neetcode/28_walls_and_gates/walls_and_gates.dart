// Walls and Gates: grid with -1 = wall, 0 = gate, inf = empty room. Fill every room with the
// distance to its nearest gate (leave inf if unreachable), in place.
// Multi-source BFS starting from all gates at once. O(rows * cols) time and space.

import 'dart:collection';

const inf = 2147483647; // LeetCode's value for an empty room

void wallsAndGates(List<List<int>> rooms) {
  final rows = rooms.length;
  if (rows == 0) return;
  final cols = rooms[0].length;
  final queue = Queue<(int, int)>();
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (rooms[r][c] == 0) queue.add((r, c)); // every gate is a source at distance 0
    }
  }
  while (queue.isNotEmpty) {
    final (r, c) = queue.removeFirst();
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
      if (rooms[nr][nc] != inf) continue; // wall, gate, or already reached by a closer gate
      rooms[nr][nc] = rooms[r][c] + 1;
      queue.add((nr, nc));
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final rooms = [
    [inf, -1, 0, inf],
    [inf, inf, inf, -1],
    [inf, -1, inf, -1],
    [0, -1, inf, inf],
  ];
  wallsAndGates(rooms);
  check(rooms, [
    [3, -1, 0, 1],
    [2, 2, 1, -1],
    [1, -1, 2, -1],
    [0, -1, 3, 4],
  ]);
  final walled = [
    [inf, -1],
    [-1, 0],
  ];
  wallsAndGates(walled);
  check(walled, [
    [inf, -1],
    [-1, 0],
  ]); // the room is sealed off
}
