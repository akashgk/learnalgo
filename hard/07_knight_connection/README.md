# Knight Connection

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** BFS on an implicit infinite graph + a halving argument

## The problem

Two knights stand on an infinite chessboard at given coordinates. In each turn, the knights may move (standard L-shaped knight moves). Return the minimum number of turns until both knights occupy the same square.

Assumption (as in AlgoExpert's version): in a turn, either knight or both may move; a knight may also stay where it is.

```
knightA = [0, 0], knightB = [4, 2]  ->  1
```

A knight needs 2 moves to get from (0, 0) to (4, 2) (for example via (2, 1)). If both move once toward each other, they meet at (2, 1) after 1 turn.

## Step 1: Reduce to a single knight

Only the **relative position** matters. Imagine knight A at the origin and ask: how many knight moves does it take to reach knight B's offset `(bx - ax, by - ay)`? Call that distance `d`.

## Step 2: Shortest path for one knight: BFS

Squares are nodes; knight moves are edges; every edge costs 1. "Fewest moves" is a shortest path in an **unweighted** graph: breadth-first search from the origin until the target is reached.

The board is infinite, so the graph is infinite, but BFS explores in distance order and stops as soon as it reaches the target. Every square is reachable by a knight, so it always terminates.

## Step 3: From one knight's distance to two knights' turns

- **Lower bound:** in one turn, both knights can each make one move, so the knight distance between them shrinks by at most 2. They need at least `ceil(d / 2)` turns.
- **Achievable:** take a shortest path of length `d` between them. Knight A walks it from one end, knight B from the other; they meet in the middle after `ceil(d / 2)` turns (for odd `d`, one knight rests on the last turn).

So the answer is `ceil(d / 2) = (d + 1) ~/ 2`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`knight_connection.dart`](knight_connection.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `target` is B's offset from A, as a record.
- `moves` lists the 8 knight moves.
- `visited` is a set of records; Dart records compare and hash by value, so `(2, 1)` created twice is the same key.
- The queue holds `((x, y), dist)` records; the first time the target is dequeued, `dist` is minimal (BFS property).
- `visited.add(next)` returns false if already present, which doubles as the "not yet visited" check.

## Step 5: Dry run for target (4, 2)

| BFS level | squares (examples) | target found? |
|---|---|---|
| 0 | (0, 0) | no |
| 1 | (1, 2), (2, 1), (2, -1), ... (8 squares) | no |
| 2 | includes (2, 1) + (2, 1) = (4, 2) | **yes**, d = 2 |

Answer: `(2 + 1) ~/ 2 = 1`.

## Complexity

- **Time: O(d^2)**: BFS explores roughly every square within knight distance d, a region whose area grows like d^2.
- **Space: O(d^2)** for the visited set and queue.

## Optimizations worth mentioning

- **Symmetry:** the distance to `(x, y)` equals the distance to `(|x|, |y|)`; restrict the search to one quadrant plus a small margin.
- **Bidirectional BFS:** search from both ends and stop when the frontiers meet; explores far fewer squares.
- **Closed-form formula:** for large distances there is an O(1) formula, with special cases near the origin.

## Common mistakes

- Returning `d` instead of `ceil(d / 2)`.
- Forgetting the visited set (the search revisits squares endlessly).

## Follow-ups

1. **Minimum Knight Moves (LeetCode #1197):** the single-knight version (`d` itself).
2. **Knight Probability in Chessboard (#688):** DP over (moves left, position).

## What to remember

Unweighted shortest path = BFS, even on an implicit infinite graph. When two agents move toward each other, the time is the distance divided by two, rounded up.
