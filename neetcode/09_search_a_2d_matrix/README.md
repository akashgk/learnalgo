# Search a 2D Matrix

**Difficulty:** Medium | **Category:** Binary Search | **Pattern:** Binary search over a virtual flattened array | **Source:** LeetCode 74; NeetCode 150

## The problem

An `m x n` matrix where each row is sorted ascending **and** the first value of each row is greater than the last value of the previous row. Return whether `target` is in the matrix, in O(log(m * n)).

```
 1  3  5  7
10 11 16 20      target 3  -> true
23 30 34 60      target 13 -> false
```

**Do not confuse** with LeetCode 240 (AlgoExpert medium 57 Search In Sorted Matrix), where rows and columns are sorted separately but rows may overlap. There, the answer is the O(m + n) staircase walk from a corner. Here, the stronger guarantee allows a true binary search.

## Step 1: See the hidden sorted array

Reading the matrix row by row gives `1 3 5 7 10 11 16 20 23 30 34 60`: one sorted list of length `m * n`. Binary search it without building it.

## Step 2: Index mapping

Position `k` in the flattened list is row `k ~/ n`, column `k % n` (`n` = number of columns). Every binary search probe converts `mid` this way.

## Step 3: Alternative: two binary searches

First binary search the rows (find the last row whose first value is <= target), then binary search inside that row. Also O(log m + log n) = O(log(mn)). The flattened version is simpler to write correctly.

## Step 4: The code

<!-- CODE:START -->

Full source: [`search_a_2d_matrix.dart`](search_a_2d_matrix.dart) (run it with `dart run`).

```dart
// Search a 2D Matrix (LeetCode 74): each row is sorted and each row starts after the previous row
// ends, so the matrix read row by row is one sorted list. Binary search over indices 0..m*n-1,
// mapping index k to (k ~/ cols, k % cols). O(log(m * n)) time, O(1) space.

bool searchMatrix(List<List<int>> matrix, int target) {
  final rows = matrix.length, cols = matrix[0].length;
  var lo = 0, hi = rows * cols - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    final value = matrix[mid ~/ cols][mid % cols];
    if (value == target) return true;
    if (value < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- `lo = 0`, `hi = rows * cols - 1`: the full virtual array.
- `matrix[mid ~/ cols][mid % cols]` reads the virtual element.
- Standard `lo <= hi` binary search for an exact value.

## Step 5: Dry run

target 3, `cols = 4`:

| lo | hi | mid | (row, col) | value | action |
|---|---|---|---|---|---|
| 0 | 11 | 5 | (1, 1) | 11 | too big: hi = 4 |
| 0 | 4 | 2 | (0, 2) | 5 | too big: hi = 1 |
| 0 | 1 | 0 | (0, 0) | 1 | too small: lo = 1 |
| 1 | 1 | 1 | (0, 1) | 3 | **found** |

## Complexity

- Time: **O(log(m * n))**.
- Space: **O(1)**.

## Edge cases

- One cell.
- Target smaller than the first element or larger than the last: the search runs off one end and returns false.

## Common mistakes

- Using `mid ~/ rows` instead of `mid ~/ cols`.
- Applying this to LeetCode 240 matrices (it is wrong there, because rows can overlap).

## Follow-ups you should be ready for

1. **LeetCode 240 variant.** Staircase search from the top-right: O(m + n).
2. **Return the position.** Return `(mid ~/ cols, mid % cols)`.
3. **Kth smallest in a row- and column-sorted matrix (LeetCode 378).** Binary search on the value, counting elements <= mid per row.

## What to remember

When a 2-D structure is one sorted sequence in disguise, binary search on the flattened index and convert with `~/` and `%`.
