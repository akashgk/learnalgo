# Transpose Matrix

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Matrix index mapping

## The problem

Given a 2D matrix of integers (at least one row and one column), return its **transpose**: the matrix flipped over its main diagonal. Row `r` becomes column `r`; the element at `(r, c)` moves to `(c, r)`.

```
[[1, 2],                 [[1, 3, 5],
 [3, 4],      ->          [2, 4, 6]]
 [5, 6]]

[[1, 2, 3]]   ->   [[1], [2], [3]]
```

### Clarifying questions

- Is the matrix square? (Not necessarily. A 3x2 input produces a 2x3 output, so in-place transposition is impossible in general.)
- Return a new matrix or modify in place? (New matrix.)
- Can rows have different lengths (jagged arrays)? (No, rectangular.)

## Step 1: Work an example by hand

Label every cell of the 3x2 example with its coordinates:

```
input (3 rows x 2 cols)        output (2 rows x 3 cols)
(0,0)=1  (0,1)=2               (0,0)=1  (0,1)=3  (0,2)=5
(1,0)=3  (1,1)=4               (1,0)=2  (1,1)=4  (1,2)=6
(2,0)=5  (2,1)=6
```

Output cell `(0, 1)` holds 3, which was input cell `(1, 0)`. Output cell `(1, 2)` holds 6, which was input `(2, 1)`. The rule: **output `(r, c)` = input `(c, r)`**, and the output has the dimensions swapped.

## Step 2: The solution

There is no brute force to improve: every one of the `w * h` values must be copied, so O(w * h) is optimal. The only design decision is **how to express the mapping** so it is hard to get wrong.

Two ways to think about it:

1. **Scatter:** for each input cell, compute where it goes: `out[c][r] = in[r][c]`.
2. **Gather:** for each output cell, compute where it comes from: `out[r][c] = in[c][r]`.

Both are correct. "Gather" pairs naturally with building the output row by row (`List.generate`), which is what the code does. In general, "gather" (define each output cell) tends to produce cleaner code and is easier to parallelize.

## Step 3: The code

<!-- CODE:START -->

Full source: [`transpose_matrix.dart`](transpose_matrix.dart) (run it with `dart run`).

```dart
// Transpose Matrix
// result[c][r] = matrix[r][c]. O(w * h) time and space.

List<List<int>> transposeMatrix(List<List<int>> matrix) {
  if (matrix.isEmpty) return [];
  final rows = matrix.length, cols = matrix[0].length;
  return List.generate(cols, (c) => List.generate(rows, (r) => matrix[r][c]));
}
```

<!-- CODE:END -->

### Walkthrough

- `if (matrix.isEmpty) return [];` is a guard. The problem promises a non-empty matrix, but the check costs nothing and prevents `matrix[0]` from throwing.
- `rows = matrix.length, cols = matrix[0].length` are the input dimensions.
- `List.generate(cols, (c) => ...)` builds `cols` output rows: the output has as many rows as the input has columns.
- `List.generate(rows, (r) => matrix[r][c])`: output row `c` is input column `c`, read top to bottom.

## Step 4: Dry run

Input `[[1, 2], [3, 4], [5, 6]]` (rows = 3, cols = 2):

| output row c | values `matrix[r][c]` for r = 0, 1, 2 | result |
|---|---|---|
| 0 | 1, 3, 5 | `[1, 3, 5]` |
| 1 | 2, 4, 6 | `[2, 4, 6]` |

## Complexity

- **Time: O(w * h)**. Every cell is read once and written once.
- **Space: O(w * h)** for the new matrix. This is required by the output, so extra space is O(1).

## In-place transpose for square matrices

For an `n x n` matrix you can transpose in place by swapping `a[i][j]` with `a[j][i]`, **but only for `j > i`** (the upper triangle). If you loop over every `(i, j)`, each pair is swapped twice and the matrix comes back unchanged. That is a very common bug.

```dart
for (var i = 0; i < n; i++) {
  for (var j = i + 1; j < n; j++) {
    final t = a[i][j];
    a[i][j] = a[j][i];
    a[j][i] = t;
  }
}
```

## Edge cases

- Single row -> single column, and vice versa.
- 1x1 matrix -> same matrix.

## Common mistakes

- Creating the output with the input's dimensions instead of swapped ones (breaks for non-square input).
- Swapping every pair in the in-place version (double swap).
- Confusing `r` and `c` names. Say them out loud as you write.

## Follow-ups

1. **Rotate an image 90 degrees clockwise in place (LeetCode #48):** transpose, then reverse each row. Counterclockwise: transpose, then reverse each column (or reverse rows first, then transpose).
2. **Spiral Traverse (medium 05)** and **Zigzag Traverse (hard 05)** are harder index-mapping problems.

## What to remember

For matrix problems, write the mapping between output and input coordinates explicitly before coding. "Output `(r, c)` comes from input `(c, r)`" is one line and prevents most bugs.
