# Longest Increasing Path in a Matrix

**Difficulty:** Hard | **Category:** 2-D Dynamic Programming | **Pattern:** Memoized DFS on a DAG | **Source:** LeetCode 329; NeetCode 150

## The problem

Return the length of the longest path in the matrix moving up, down, left or right, where every step goes to a **strictly larger** value.

```
9 9 4
6 6 8      ->  4   (1 -> 2 -> 6 -> 9)
2 1 1
```

## Step 1: Brute force

DFS from every cell, trying every increasing path: exponential in the worst case, because the same cell is re-explored through many different paths.

## Step 2: Why memoization is safe here

The longest path **starting** at a cell does not depend on how you arrived there. Could it depend on which cells were already used (like in Word Search)? No: moves are strictly increasing, so a path can never revisit a cell (that would require going back to a smaller value). The graph "cell -> larger neighbor" is a **DAG**, and in a DAG, "longest path from X" is a well-defined subproblem:

```
longest(cell) = 1 + max(longest(neighbor) for neighbors with a larger value), or 1 if none
```

Memoize it: each cell is computed once.

## Step 3: Alternative: topological order

Process cells from the largest values down (or peel "sinks" with in-degree counting like Kahn's algorithm); the number of layers is the answer. Same O(mn), no recursion.

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_increasing_path_in_a_matrix.dart`](longest_increasing_path_in_a_matrix.dart) (run it with `dart run`).

```dart
// Longest Increasing Path in a Matrix: longest path moving up/down/left/right to strictly larger
// values. Strictly increasing moves can never cycle, so the "longest path from cell" values form a
// DAG DP: memoized DFS. O(rows * cols) time and space.

int longestIncreasingPath(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  final memo = List.generate(rows, (_) => List<int>.filled(cols, 0)); // 0 = not computed yet
  int longestFrom(int r, int c) {
    if (memo[r][c] != 0) return memo[r][c];
    var best = 1; // the cell alone
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
      if (matrix[nr][nc] > matrix[r][c]) {
        final len = 1 + longestFrom(nr, nc);
        if (len > best) best = len;
      }
    }
    return memo[r][c] = best;
  }

  var answer = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final len = longestFrom(r, c);
      if (len > answer) answer = len;
    }
  }
  return answer;
}
```

<!-- CODE:END -->

### Walkthrough

- `memo[r][c] == 0` means "not computed" (every real answer is at least 1).
- `return memo[r][c] = best;` stores and returns in one expression.
- No visited set is needed: strictly increasing moves cannot cycle.

## Step 5: Dry run

The memo table after all calls (longest path starting at each cell):

```
1 1 2
2 2 1
3 4 2
```

- `(0, 0) = 9` and `(0, 1) = 9`: no larger neighbor: 1.
- `(1, 0) = 6`: goes to 9: 2.
- `(2, 0) = 2`: goes to 6 (length 2): 3.
- `(2, 1) = 1`: goes to 2 (length 3): **4**, the path 1 -> 2 -> 6 -> 9.

## Complexity

- Time: **O(m * n)**: each cell computed once, 4 neighbors each.
- Space: **O(m * n)** for the memo and the recursion depth (a long snake-shaped increasing path can be O(mn) deep).

## Edge cases

- One cell: 1.
- All equal: 1 (strictly larger is required).

## Common mistakes

- Adding a visited set (unnecessary, and wrong if not reset between starts).
- Non-strict comparison (`>=`), which creates cycles between equal cells.
- Memoizing "longest path ending here" and "starting here" inconsistently.

## Follow-ups you should be ready for

1. **Return the path.** Store the best next cell for each cell.
2. **Longest increasing subsequence.** The 1-D sequence version; AlgoExpert very_hard 14.
3. **Deep recursion.** Use the topological (Kahn-style) BFS version.

## What to remember

If the moves can never revisit a state (strictly increasing, a DAG), "best path from here" is a memoizable subproblem, and DFS + memo is O(states).
