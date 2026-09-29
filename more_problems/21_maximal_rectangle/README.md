# Maximal Rectangle

**Difficulty:** Hard | **Category:** Stacks / Dynamic Programming | **Pattern:** Reduce to Largest Rectangle in Histogram, row by row | **Source:** LeetCode 85; Striver A2Z

## The problem

Given a binary matrix of `'0'` and `'1'`, find the area of the largest rectangle containing only 1s.

```
1 0 1 0 0
1 0 1 1 1
1 1 1 1 1      ->  6   (rows 1-2, columns 2-4)
1 0 0 1 0
```

## Step 1: Brute force

Every rectangle is defined by two rows and two columns: O(R^2 C^2) rectangles, and checking one naively costs O(RC). Even with 2-D prefix sums to check in O(1), O(R^2 C^2) is too slow.

## Step 2: Fix the bottom row

Every rectangle has a **bottom row**. Fix it. For each column, count how many consecutive 1s stand on top of that row, going upward: the **height** of that column. For the third row (index 2) of the example:

```
heights = [3, 1, 3, 2, 2]
```

A rectangle whose bottom edge sits on this row is a rectangle **under a histogram** with these bar heights. So the problem becomes: run **Largest Rectangle in Histogram** (AlgoExpert hard 52, Largest Rectangle Under Skyline) once per row, and take the best.

Updating heights from one row to the next is O(C): `height = row[c] == '1' ? height + 1 : 0`.

## Step 3: Largest rectangle in a histogram, in O(n)

For each bar `i`, the widest rectangle of height exactly `heights[i]` extends left and right until the nearest **shorter** bar on each side. (This is the same "previous/next smaller element" idea as more_problems 19.)

Monotonic stack of indices with increasing heights. When bar `i` arrives and is not taller than the top, the top bar has found its **right** boundary (`i`, the first bar that is not taller). Its **left** boundary is the index just below it on the stack (the previous shorter bar). Pop it and compute its area: `height * (i - leftBoundary - 1)`.

A sentinel bar of height 0 after the end pops everything left on the stack.

Ties: popping on `>=` means an equal bar pops the earlier one with a width that is too short. That is fine: the later equal bar will extend further left over it (it is not blocked by an equal bar) and compute the full width.

## Step 4: The code

<!-- CODE:START -->

Full source: [`maximal_rectangle.dart`](maximal_rectangle.dart) (run it with `dart run`).

```dart
// Maximal Rectangle: largest all-1 rectangle in a binary matrix.
// Treat each row as the floor of a histogram of consecutive 1s above it, and run
// "largest rectangle in histogram" (monotonic stack) on every row. O(rows * cols) time, O(cols) space.

int maximalRectangle(List<String> matrix) {
  if (matrix.isEmpty) return 0;
  final cols = matrix[0].length;
  final heights = List<int>.filled(cols, 0);
  var best = 0;
  for (final row in matrix) {
    for (var c = 0; c < cols; c++) {
      heights[c] = row[c] == '1' ? heights[c] + 1 : 0;
    }
    final area = largestRectangleInHistogram(heights);
    if (area > best) best = area;
  }
  return best;
}

/// For each bar, the widest rectangle using its full height extends to the nearest
/// strictly shorter bar on each side. A bar's right boundary is found when it is popped.
int largestRectangleInHistogram(List<int> heights) {
  final stack = <int>[]; // indices with increasing heights
  var best = 0;
  for (var i = 0; i <= heights.length; i++) {
    final h = i == heights.length ? 0 : heights[i]; // sentinel 0 flushes the stack at the end
    while (stack.isNotEmpty && heights[stack.last] >= h) {
      final height = heights[stack.removeLast()];
      final leftBoundary = stack.isEmpty ? -1 : stack.last; // nearest shorter bar on the left
      final width = i - leftBoundary - 1;
      if (height * width > best) best = height * width;
    }
    stack.add(i);
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `heights` is reused across rows; only O(C) extra space.
- `largestRectangleInHistogram` iterates to `heights.length` inclusive; the extra step uses height 0 as the sentinel.
- `leftBoundary = stack.isEmpty ? -1 : stack.last`: when the stack is empty, the popped bar was the shortest so far and extends all the way to the left edge.

## Step 5: Dry run

Histogram `[2, 1, 5, 6, 2, 3]`:

| i (height) | popped bar | width | area | best |
|---|---|---|---|---|
| 1 (1) | height 2 | 1 | 2 | 2 |
| 4 (2) | height 6 | 1 | 6 | 6 |
| 4 (2) | height 5 | 2 | 10 | 10 |
| 6 (sentinel 0) | height 3 | 1 | 3 | 10 |
| 6 (sentinel 0) | height 2 | 4 | 8 | 10 |
| 6 (sentinel 0) | height 1 | 6 | 6 | 10 |

The matrix, row by row:

| row | heights | largest in histogram |
|---|---|---|
| `10100` | 1 0 1 0 0 | 1 |
| `10111` | 2 0 2 1 1 | 3 |
| `11111` | 3 1 3 2 2 | **6** (height 2, columns 2-4) |
| `10010` | 4 0 0 3 0 | 4 |

## Complexity

- Time: **O(R * C)**. Each row's histogram pass is O(C).
- Space: **O(C)**.

## Edge cases

- All zeros: 0.
- A single row: the longest run of 1s.
- Empty matrix: 0 (guarded).

## Common mistakes

- Not resetting the height to 0 on a `'0'` cell (heights must count **consecutive** 1s).
- Forgetting the sentinel, leaving bars on the stack unprocessed.
- Width off by one: it is `i - leftBoundary - 1`, the bars strictly between the two shorter boundaries.

## Follow-ups you should be ready for

1. **Maximal Square (LeetCode 221).** Simpler DP: `dp[r][c] = 1 + min(up, left, up-left)`.
2. **Count submatrices with all ones (LeetCode 1504).** Same heights idea with a stack that counts.
3. **Alternative O(RC) DP** that tracks, for each column, the left and right extent of the current height. Same complexity; the stack version reuses a known building block.

## What to remember

A 2-D "largest block" problem often becomes a 1-D problem per row: accumulate heights, then solve the histogram problem with a monotonic stack.
