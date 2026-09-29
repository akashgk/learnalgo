# Square Of Zeroes

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** Precomputed run lengths for O(1) border checks

## The problem

Given an `n x n` matrix of 0s and 1s, return whether it contains a square of side **at least 2** whose **border** is made entirely of 0s. The interior does not matter.

```
[[1, 1, 1, 0, 1, 0],
 [0, 0, 0, 0, 0, 1],
 [0, 1, 1, 1, 0, 1],
 [0, 0, 0, 1, 0, 1],
 [0, 1, 1, 1, 0, 1],
 [0, 0, 0, 0, 0, 1]]   ->  true   (the 5x5 square from (1, 0) to (5, 4))
```

## Step 1: Count the candidates

A square is determined by its top-left corner and its side length: O(n^2) corners times O(n) sizes = **O(n^3) candidate squares**.

## Step 2: Brute force

For each candidate, walk its four sides: O(n) per candidate. **O(n^4)** total.

## Step 3: Make each border check O(1)

**Duplicated work:** the same runs of zeros are re-walked for many squares. Precompute, for every cell:

- `right[r][c]` = how many consecutive 0s start at `(r, c)` going **right**;
- `down[r][c]` = how many consecutive 0s start at `(r, c)` going **down**.

Both fill in one backward pass: `right[r][c] = 1 + right[r][c + 1]` if the cell is 0, else 0 (and similarly for `down`).

A square with top-left `(r, c)` and side `k` has an all-zero border iff all four sides are long enough:

```
top edge:     right[r][c]         >= k
left edge:    down[r][c]          >= k
bottom edge:  right[r + k - 1][c] >= k
right edge:   down[r][c + k - 1]  >= k
```

Each candidate is now O(1): **O(n^3)** total.

## Step 4: The code

<!-- CODE:START -->

Full source: [`square_of_zeroes.dart`](square_of_zeroes.dart) (run it with `dart run`).

```dart
// Square Of Zeroes: does the 0/1 matrix contain a square (side >= 2) whose border is all 0s?
// Precompute, for each cell, how many consecutive 0s extend right and down. Then each candidate
// square's border is checked in O(1). O(n^3) time, O(n^2) space.

bool squareOfZeroes(List<List<int>> matrix) {
  final n = matrix.length;
  final right = List.generate(n, (_) => List<int>.filled(n, 0));
  final down = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var r = n - 1; r >= 0; r--) {
    for (var c = n - 1; c >= 0; c--) {
      if (matrix[r][c] != 0) continue;
      right[r][c] = 1 + (c + 1 < n ? right[r][c + 1] : 0);
      down[r][c] = 1 + (r + 1 < n ? down[r + 1][c] : 0);
    }
  }
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      for (var size = 2; r + size <= n && c + size <= n; size++) {
        final last = size - 1;
        if (right[r][c] >= size && down[r][c] >= size && right[r + last][c] >= size && down[r][c + last] >= size) {
          return true;
        }
      }
    }
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- The backward double loop fills `right` and `down` (0 for cells containing 1).
- The triple loop tries every top-left corner and size, and checks the four conditions.
- Returns true at the first valid square.

## Step 5: Dry run (the 5x5 square in the example)

Top-left `(1, 0)`, side 5, so `last = 4`:

| check | value | needs >= 5 |
|---|---|---|
| right[1][0] (top edge) | 5 (cells (1,0)..(1,4) are 0) | yes |
| down[1][0] (left edge) | 5 (cells (1,0)..(5,0)) | yes |
| right[5][0] (bottom edge) | 5 (cells (5,0)..(5,4)) | yes |
| down[1][4] (right edge) | 5 (cells (1,4)..(5,4)) | yes |

All four pass: true. (The smaller candidates checked earlier fail at least one condition.)

## Complexity

- **Time: O(n^3)**.
- **Space: O(n^2)** for the two tables.

## Common mistakes

- Checking the interior (the problem only cares about the border).
- Allowing side length 1 (a single 0 does not count).
- Off-by-one on the bottom and right edges (`k - 1`, not `k`).

## Follow-ups

1. **Largest 1-Bordered Square (LeetCode #1139):** the same tables; return the largest size. Iterate sizes from large to small for early exit.
2. **Maximal Square (#221):** a **filled** square of 1s; a different DP (`dp[i][j] = 1 + min(up, left, diagonal)`).

## What to remember

When many candidates need "is this segment all zeros?", precompute run lengths from every cell in each direction; each check becomes a comparison.
