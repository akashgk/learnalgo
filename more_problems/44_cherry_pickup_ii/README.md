# Cherry Pickup II

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 3-D grid DP with two agents moving in lockstep | **Source:** LeetCode 1463; Striver A2Z (as "Ninja and his friends")

## The problem

A grid of cherry counts. Robot 1 starts at the top-left cell, robot 2 at the top-right cell. Each step, both robots move **down one row**, and each can move to column `c - 1`, `c`, or `c + 1`. Each robot collects the cherries of every cell it visits; if both are in the same cell, the cherries count **once**. Maximize the total when they reach the bottom row.

```
3 1 1
2 5 1        ->  24
1 5 5
2 1 1
```

Robot 1: 3, 2, 5, 2 = 12. Robot 2: 1, 5, 5, 1 = 12.

## Step 1: Why two independent single-robot DPs fail

Maximizing each robot separately and adding can double count shared cells, and the best solo path for robot 2 may take cherries robot 1 needed. The robots interact only through **shared cells**, and that interaction depends on **where both are in the same row**. So the state must include both positions.

## Step 2: Choose the state

Both robots are always in the **same row** (they move down together). So the state is `(row, col1, col2)`, not four coordinates.

```
best(r, c1, c2) = cherries collected in row r at (c1, c2)
                + max over (d1, d2) in {-1, 0, 1}^2 of best(r + 1, c1 + d1, c2 + d2)
```

where the cherries in row r are `grid[r][c1] + grid[r][c2]`, or just `grid[r][c1]` when `c1 == c2`.

## Step 3: Brute force size vs DP size

Each robot has 3 choices per row: `9^rows` joint paths. The DP has `rows * cols^2` states with 9 transitions each: `O(rows * cols^2 * 9)`. For a 70 x 70 grid that is about 3 million operations.

## Step 4: Forward, one row at a time

The code runs the DP **forward** (top to bottom): `dp[c1][c2]` is the best total with the robots at `(c1, c2)` in the current row. Unreachable states are marked with a large negative sentinel, because a robot cannot jump more than one column per row. (For example, robot 1 starts at column 0, so after 1 step it can only be in column 0 or 1.) Each row, every reachable state pushes its value into up to 9 states of the next row. The answer is the maximum over the last row.

Only two `cols x cols` layers are kept at once: O(cols^2) space.

## Step 5: The code

<!-- CODE:START -->

Full source: [`cherry_pickup_ii.dart`](cherry_pickup_ii.dart) (run it with `dart run`).

```dart
// Cherry Pickup II: two robots start at the top-left and top-right corners and move down one row
// per step (column -1, 0, or +1). Each collects the cherries of the cells it visits; a cell shared
// by both counts once. Maximize the total.
// DP over (row, col1, col2), both robots moving together. O(rows * cols^2 * 9) time, O(cols^2) space.

int cherryPickup(List<List<int>> grid) {
  final rows = grid.length, cols = grid[0].length;
  const neg = -1 << 40; // unreachable state
  // dp[c1][c2]: best total with robot 1 at column c1 and robot 2 at c2 in the current row.
  var dp = List.generate(cols, (_) => List<int>.filled(cols, neg));
  dp[0][cols - 1] = grid[0][0] + (cols > 1 ? grid[0][cols - 1] : 0);
  for (var r = 1; r < rows; r++) {
    final next = List.generate(cols, (_) => List<int>.filled(cols, neg));
    for (var c1 = 0; c1 < cols; c1++) {
      for (var c2 = 0; c2 < cols; c2++) {
        if (dp[c1][c2] == neg) continue;
        for (var d1 = -1; d1 <= 1; d1++) {
          for (var d2 = -1; d2 <= 1; d2++) {
            final n1 = c1 + d1, n2 = c2 + d2;
            if (n1 < 0 || n2 < 0 || n1 >= cols || n2 >= cols) continue;
            final gain = grid[r][n1] + (n1 == n2 ? 0 : grid[r][n2]);
            if (dp[c1][c2] + gain > next[n1][n2]) next[n1][n2] = dp[c1][c2] + gain;
          }
        }
      }
    }
    dp = next;
  }
  var best = 0;
  for (final row in dp) {
    for (final v in row) {
      if (v > best) best = v;
    }
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `dp[0][cols - 1]` starts with row 0's cherries; the `cols > 1` guard avoids counting a 1-column grid's only cell twice.
- `if (dp[c1][c2] == neg) continue;` skips unreachable states.
- `gain` handles the shared-cell rule with `n1 == n2 ? 0 : grid[r][n2]`.
- The final double loop takes the best reachable state in the last row.

## Step 6: Dry run

Example grid. Best path pair per row:

| row | robot 1 col (cherries) | robot 2 col (cherries) | running total |
|---|---|---|---|
| 0 | 0 (3) | 2 (1) | 4 |
| 1 | 0 (2) | 1 (5) | 11 |
| 2 | 1 (5) | 2 (5) | 21 |
| 3 | 0 (2) | 1 (1) | **24** |

The DP evaluates every reachable `(c1, c2)` pair per row; this table shows the pair of paths that the maximum comes from.

## Complexity

- Time: **O(rows * cols^2 * 9)**.
- Space: **O(cols^2)**.

## Edge cases

- One column: both robots share every cell; the total is the column sum.
- One row: the two corner cells (or one cell if `cols == 1`).
- Zeros everywhere: 0.

## Common mistakes

- Counting a shared cell twice.
- Letting robots start anywhere (unreachable states must stay invalid).
- Using a 4-D state `(r1, c1, r2, c2)` when the rows are always equal.

## Follow-ups you should be ready for

1. **Symmetry pruning.** Robots never benefit from crossing, so you can restrict to `c1 <= c2`, roughly halving the work.
2. **Cherry Pickup I (LeetCode 741).** One robot goes down-right and back; model it as **two robots going down-right at the same time**, state `(step, r1, r2)` with `c = step - r`. Same "move in lockstep" trick.
3. **Top-down memoization.** `best(r, c1, c2)` recursively with a memo table; often quicker to write.

## What to remember

When two agents interact through shared cells, put both positions in the state, and move them in lockstep so that one time coordinate (here, the row) is shared. That keeps the state at `rows * cols^2` instead of `(rows * cols)^2`.
