# Minimum Passes Of Matrix

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Multi-source BFS (BFS levels = time)

## The problem

An integer matrix is given. In one **pass**, every negative number that is horizontally or vertically adjacent to a positive number becomes positive (its sign flips). Zero is neither positive nor negative, and it never spreads anything. A number that becomes positive during a pass only affects other numbers in the **next** pass. Return the minimum number of passes to make every negative number positive, or -1 if that is impossible.

```
[[ 0, -1, -3,  2,  0],
 [ 1, -2, -5, -1, -3],
 [ 3,  0,  0, -4, -1]]   ->  3
```

## Step 1: Work an example by hand

The initial positives are `2` at (0,3), `1` at (1,0), `3` at (2,0).

- **Pass 1:** negatives next to them flip: (0,2), (1,3), (1,1).
- **Pass 2:** negatives next to the cells flipped in pass 1 flip: (0,1), (1,2), (1,4), (2,3).
- **Pass 3:** (2,4) flips (next to (2,3)).

No negatives remain: 3 passes.

Notice that in each pass, only neighbors of the cells that **became** positive in the previous pass can change. It spreads like a wave, one ring per pass, starting from all initial positives at once.

## Step 2: Brute force: simulate on the whole matrix

Each pass, scan the whole matrix and flip negatives next to positives, using a copy so that flips in this pass do not cascade. Up to O(w * h) passes, each O(w * h): **O((w * h)^2)**.

## Step 3: Optimize: BFS from all positives at once

The wave spreading is exactly **breadth-first search**, where the BFS level is the pass number. Because the wave starts from **all** initial positives simultaneously, put all of them in the queue at the start: **multi-source BFS**.

- Level 0 queue: every initially positive cell.
- To build level k + 1: for each cell in level k, flip its negative neighbors and put them into the next level.
- Each level that flips something is one pass.

Processing strictly level by level (a fresh queue per pass) enforces the rule "new positives only act in the next pass".

Count negatives at the start and decrement on each flip; if any remain when the BFS runs out, return -1 (they are unreachable, for example walled in by zeros).

## Step 4: The code

<!-- CODE:START -->

Full source: [`minimum_passes_of_matrix.dart`](minimum_passes_of_matrix.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- The first double loop enqueues all positives and counts negatives.
- `while (queue.isNotEmpty && negatives > 0)` processes one pass per iteration.
- `final next = Queue<(int, int)>();` collects cells flipped in this pass.
- `matrix[nr][nc] *= -1;` flips a negative neighbor; flipping in place also marks it as visited (it is no longer negative).
- After the pass: `queue = next; passes++`.
- The final line returns -1 if negatives remain.

## Step 5: Dry run

| pass | cells flipped | negatives left |
|---|---|---|
| start | | 8 |
| 1 | (0,2), (1,3), (1,1) | 5 |
| 2 | (0,1), (1,2), (1,4), (2,3) | 1 |
| 3 | (2,4) | 0 |

Answer: 3.

## Complexity

- **Time: O(w * h)**: every cell enters a queue at most once.
- **Space: O(w * h)** for the queues.

## Common mistakes

- Letting cells flipped in the current pass flip their neighbors in the same pass (single queue without level boundaries, or in-place flipping during a full-matrix scan).
- Counting a final empty pass (the loop stops as soon as `negatives == 0`).
- Treating 0 as positive.

## Follow-ups

1. **Rotting Oranges (LeetCode #994):** identical structure.
2. **01 Matrix (#542):** distance from every cell to the nearest 0; multi-source BFS from all zeros.
3. **Walls and Gates (#286):** distance to the nearest gate.

## What to remember

"Something spreads from many sources at once, one step per unit of time" = multi-source BFS; the BFS level is the time.
