# Maximum Sum Submatrix

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 2D prefix sums

## The problem

Given a 2D matrix of integers (possibly negative) and a positive integer `size`, return the largest sum of any `size x size` square submatrix. `size` never exceeds the matrix dimensions.

```
matrix = [[ 5,  3, -1,  5],
          [-7,  3,  7,  4],
          [12,  8,  0,  0],
          [ 1, -8, -8,  2]],  size = 2

->  18    ([[3, 7], [8, 0]])
```

## Step 1: Brute force

For each of the `(rows - size + 1) * (cols - size + 1)` positions, add up `size^2` cells: **O(w * h * size^2)**. The work of summing overlapping squares is repeated.

## Step 2: Warm-up: 1D prefix sums

For an array, `P[i]` = sum of the first i elements. Then the sum of `a[i..j)` is `P[j] - P[i]`: any range sum in O(1).

## Step 3: 2D prefix sums

`P[r][c]` = sum of the rectangle from `(0, 0)` to `(r - 1, c - 1)` (the top-left r x c block). Build it with **inclusion-exclusion**:

```
P[r+1][c+1] = matrix[r][c] + P[r][c+1] + P[r+1][c] - P[r][c]
```

The block above and the block to the left both include the top-left corner block, so it is counted twice and subtracted once.

The sum of any rectangle is then also inclusion-exclusion. For a `size x size` square whose bottom-right exclusive corner is `(r, c)`:

```
sum = P[r][c] - P[r - size][c] - P[r][c - size] + P[r - size][c - size]
```

Picture: take the big top-left block, remove the strip above the square and the strip left of it, and add back the corner you removed twice.

Padding `P` with an extra zero row and column removes all boundary special cases.

## Step 4: The code

<!-- CODE:START -->

Full source: [`maximum_sum_submatrix.dart`](maximum_sum_submatrix.dart) (run it with `dart run`).

```dart
// Maximum Sum Submatrix: largest sum of any size x size submatrix.
// 2D prefix sums give each submatrix sum in O(1). O(w * h) time and space.

int maximumSumSubmatrix(List<List<int>> matrix, int size) {
  final rows = matrix.length, cols = matrix[0].length;
  // p[r][c] = sum of matrix[0..r) x [0..c)
  final p = List.generate(rows + 1, (_) => List<int>.filled(cols + 1, 0));
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      p[r + 1][c + 1] = matrix[r][c] + p[r][c + 1] + p[r + 1][c] - p[r][c];
    }
  }
  int? best;
  for (var r = size; r <= rows; r++) {
    for (var c = size; c <= cols; c++) {
      final sum = p[r][c] - p[r - size][c] - p[r][c - size] + p[r - size][c - size];
      if (best == null || sum > best) best = sum;
    }
  }
  return best!;
}
```

<!-- CODE:END -->

### Walkthrough

- `p` is `(rows + 1) x (cols + 1)`, with row 0 and column 0 all zeros.
- The first double loop builds the prefix table.
- The second double loop evaluates every square in O(1).
- `int? best` starts as null so an all-negative matrix still returns its true maximum.

## Step 5: Dry run (the winning square)

The square `[[3, 7], [8, 0]]` covers rows 1..2 and columns 1..2, so its exclusive bottom-right corner is `(3, 3)`:

- `P[3][3]` = sum of rows 0..2, cols 0..2 = 5 + 3 - 1 - 7 + 3 + 7 + 12 + 8 + 0 = 30
- `P[1][3]` = row 0, cols 0..2 = 5 + 3 - 1 = 7
- `P[3][1]` = rows 0..2, col 0 = 5 - 7 + 12 = 10
- `P[1][1]` = 5

`30 - 7 - 10 + 5 = 18`. Correct.

## Complexity

- **Time: O(w * h)**: building the table and scanning all squares are both linear in the number of cells.
- **Space: O(w * h)** for the prefix table.

## Common mistakes

- Off-by-one between inclusive and exclusive corners.
- Initializing the best with 0 (fails when every sum is negative).

## Follow-ups

1. **Range Sum Query 2D (LeetCode #304):** build once, answer any rectangle query in O(1).
2. **Matrix Block Sum (#1314).**
3. **Max sum rectangle of any size:** fix a pair of rows, collapse the columns between them into a 1D array of column sums, run Kadane's algorithm: O(rows^2 * cols).

## What to remember

Prefix sums extend to 2D with inclusion-exclusion. After O(w * h) preprocessing, any rectangle sum is O(1).
