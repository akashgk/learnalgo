# Walls and Gates

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Multi-source BFS | **Source:** LeetCode 286 (premium); NeetCode 150

## The problem

A grid where `-1` is a wall, `0` is a gate, and `2147483647` (INF) is an empty room. Fill each empty room with the distance to its **nearest** gate (4-directional moves, walls block). Rooms that cannot reach any gate stay INF. Modify the grid in place.

```
INF  -1   0  INF          3  -1   0   1
INF INF INF   -1    ->    2   2   1  -1
INF  -1 INF   -1          1  -1   2  -1
  0  -1 INF  INF          0  -1   3   4
```

## Step 1: Brute force

BFS from every room until it finds a gate: O((mn)^2). Or BFS from every gate and keep the minimum per room: O(g * mn) for g gates.

## Step 2: Start from all gates at once

Put **every gate** in the queue at distance 0, then run a single BFS. BFS explores in order of distance from the **set** of sources, so the first time a room is reached, it is reached from its **nearest** gate. Assign the distance and never touch the room again.

This is **multi-source BFS**: equivalent to adding one virtual super-source connected to every gate with a 0-cost edge. AlgoExpert medium 42 Minimum Passes Of Matrix (Rotting Oranges) is the same technique.

## Step 3: Using the grid as the visited set

A room is unvisited exactly while it still holds INF. Setting its distance marks it visited, so no extra memory is needed.

## Step 4: The code

<!-- CODE:START -->

Full source: [`walls_and_gates.dart`](walls_and_gates.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- The first loop enqueues all gates.
- `rooms[nr][nc] != inf` skips walls, gates and already-filled rooms in one comparison.
- `rooms[nr][nc] = rooms[r][c] + 1`: a neighbor is one step farther than the current cell.

## Step 5: Dry run

Gates at (0, 2) and (3, 0) start the queue. Distances spread in rings:

| BFS layer | cells filled |
|---|---|
| 1 | (0, 3), (1, 2) from the top gate; (2, 0) from the bottom gate |
| 2 | (1, 1), (2, 2) from (1, 2); (1, 0) from (2, 0) |
| 3 | (0, 0) from (1, 0); (3, 2) from (2, 2) |
| 4 | (3, 3) from (3, 2) |

Each room gets the layer at which it was first reached.

## Complexity

- Time: **O(m * n)**: each cell is enqueued at most once.
- Space: **O(m * n)** for the queue in the worst case.

## Edge cases

- No gates: nothing changes.
- A room walled off from all gates: stays INF.
- Grid of only walls or only gates.

## Common mistakes

- BFS from each room separately.
- DFS instead of BFS (DFS does not visit in distance order; you would need to keep relaxing distances).
- Marking visited on dequeue instead of on enqueue (cells get enqueued many times).

## Follow-ups you should be ready for

1. **Rotting Oranges (LeetCode 994).** Multi-source BFS from rotten oranges; count layers.
2. **01 Matrix (LeetCode 542).** Distance to the nearest 0 for every cell.
3. **As Far from Land as Possible (LeetCode 1162).** Multi-source BFS from land; the last layer is the answer.

## What to remember

"Distance to the nearest of many sources" = one BFS started from all sources at once.
