// Knight Connection: two knights on an infinite board move simultaneously (one move each
// per turn, either may also stay). Min turns to land on the same square =
// ceil(knightDistance / 2). BFS from knight A's relative offset. O(d^2) time and space.

import 'dart:collection';

int knightConnection(List<int> knightA, List<int> knightB) {
  final target = (knightB[0] - knightA[0], knightB[1] - knightA[1]);
  const moves = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)];
  final visited = <(int, int)>{(0, 0)};
  final queue = Queue<((int, int), int)>()..add(((0, 0), 0));
  while (queue.isNotEmpty) {
    final ((x, y), dist) = queue.removeFirst();
    if ((x, y) == target) return (dist + 1) ~/ 2;
    for (final (dx, dy) in moves) {
      final next = (x + dx, y + dy);
      if (visited.add(next)) queue.add((next, dist + 1));
    }
  }
  throw StateError('unreachable: a knight can reach every square');
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(knightConnection([0, 0], [4, 2]), 1); // knight distance 2
  check(knightConnection([0, 0], [0, 0]), 0);
  check(knightConnection([0, 0], [1, 2]), 1); // distance 1 -> ceil(1/2) = 1
  check(knightConnection([0, 0], [1, 1]), 1); // distance 2
  check(knightConnection([10, 10], [-10, -10]), 7); // distance 14
}
