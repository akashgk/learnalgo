# Search In Sorted Matrix

**Difficulty:** Medium | **Category:** Searching | **Pattern:** Staircase search from a corner

## The problem

Every row of a matrix is sorted ascending left to right, and every column is sorted ascending top to bottom. Rows are **not** continuations of each other (the first element of a row can be smaller than the last element of the previous row). Given a target, return its position `[row, col]`, or `[-1, -1]` if absent.

```
[[  1,   4,   7,  12,   15, 1000],
 [  2,   5,  19,  31,   32, 1001],
 [  3,   8,  24,  33,   35, 1002],
 [ 40,  41,  42,  44,   45, 1003],
 [ 99, 100, 103, 106,  128, 1004]]

target 44  ->  [3, 3]
```

## Step 1: Brute force and a better baseline

- Check every cell: O(n * m).
- Binary search each row: O(n log m). Better, but it only uses the row ordering.

Can we use both orderings at once?

## Step 2: Find a corner where the directions disagree

At the **top-left** corner (1), moving right increases and moving down increases. If the target is bigger, both directions look promising: no decision is possible.

At the **top-right** corner (1000), moving **left decreases** and moving **down increases**. Now every comparison gives a decision:

- `value > target`: everything **below** in this column is even bigger, so the whole column is useless. Move left.
- `value < target`: everything to the **left** in this row is even smaller, so the whole row is useless. Move down.

Each step eliminates an entire row or column. (The bottom-left corner works equally well, with the directions mirrored.)

## Step 3: The code

<!-- CODE:START -->

Full source: [`search_in_sorted_matrix.dart`](search_in_sorted_matrix.dart) (run it with `dart run`).

```dart
// Search In Sorted Matrix: rows and columns sorted ascending. Start at the top-right corner:
// too big -> move left, too small -> move down. O(n + m) time, O(1) space.

List<int> searchInSortedMatrix(List<List<int>> matrix, int target) {
  var row = 0, col = matrix[0].length - 1;
  while (row < matrix.length && col >= 0) {
    final value = matrix[row][col];
    if (value == target) return [row, col];
    if (value > target) {
      col--; // everything below in this column is even bigger
    } else {
      row++; // everything left in this row is even smaller
    }
  }
  return [-1, -1];
}
```

<!-- CODE:END -->

### Walkthrough

- Start at `row = 0`, `col = last column`.
- Loop while still inside the matrix.
- Compare and move left or down as in Step 2.

## Step 4: Dry run (target 44)

| position | value | action |
|---|---|---|
| (0, 5) | 1000 | > 44, move left |
| (0, 4) | 15 | < 44, move down |
| (1, 4) | 32 | < 44, move down |
| (2, 4) | 35 | < 44, move down |
| (3, 4) | 45 | > 44, move left |
| (3, 3) | 44 | found: [3, 3] |

## Complexity

- **Time: O(n + m)**: each step removes a row or a column, so at most `n + m` steps.
- **Space: O(1)**.

## Common mistakes

- Starting at the top-left or bottom-right corner (no decision possible).
- Treating the matrix as one sorted list (it is not, in this problem).

## Follow-ups

1. **Search a 2D Matrix II (LeetCode #240):** identical.
2. **Search a 2D Matrix (#74):** the matrix **is** fully sorted row by row (each row starts after the previous ends). Then treat it as a 1D array of length n * m and binary search: O(log(n * m)), with `row = index ~/ m`, `col = index % m`.
3. **k-th smallest element in a sorted matrix (#378):** binary search on the value, counting elements <= mid with the same staircase walk.

## What to remember

In a row- and column-sorted matrix, start at a corner where one direction increases and the other decreases: every comparison eliminates a whole row or column.
