# Rectangle Mania

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Canonical diagonal + hash set of points

## The problem

Given a list of distinct 2D points, count the rectangles **parallel to the axes** whose four corners are all in the list.

```
points on two rows: (0,0) (1,0) (2,0) (3,0) and (0,1) (1,1) (2,1) (3,1)
->  6     (any 2 of the 4 columns form a rectangle: C(4, 2) = 6)
```

## Step 1: Brute force

All combinations of 4 points: **O(n^4)**.

## Step 2: One diagonal determines the rectangle

As in Minimum Area Rectangle (very hard 04), two opposite corners `(x1, y1)` and `(x2, y2)` fix the other two: `(x1, y2)` and `(x2, y1)`. With points in a hash set, checking a pair is O(1).

## Step 3: Count each rectangle exactly once

Every rectangle has **two** diagonals, and each diagonal can be seen from either end, so a naive pair loop counts each rectangle 4 times (or 2 times if you only visit each unordered pair once). Instead of dividing, pick a **canonical diagonal**: only count the pair where the first point is the **lower-left** corner and the second is the **upper-right** corner (`x2 > x1` and `y2 > y1`). Every rectangle has exactly one such diagonal.

## Step 4: The code

<!-- CODE:START -->

Full source: [`rectangle_mania.dart`](rectangle_mania.dart) (run it with `dart run`).

```dart
// Rectangle Mania: count axis-aligned rectangles whose 4 corners are in the point set.
// Treat each pair as the diagonal going up-right; check the other two corners.
// O(n^2) time, O(n) space.

int rectangleMania(List<List<int>> coords) {
  final set = {for (final [x, y] in coords) (x, y)};
  var count = 0;
  for (final [x1, y1] in coords) {
    for (final [x2, y2] in coords) {
      // Only count the lower-left -> upper-right diagonal so each rectangle is counted once.
      if (x2 > x1 && y2 > y1 && set.contains((x1, y2)) && set.contains((x2, y1))) count++;
    }
  }
  return count;
}
```

<!-- CODE:END -->

### Walkthrough

- The set holds points as records.
- The double loop considers ordered pairs; the condition `x2 > x1 && y2 > y1` keeps only lower-left to upper-right diagonals.
- `set.contains((x1, y2)) && set.contains((x2, y1))` checks the other two corners.

## Step 5: Dry run (two rows, 4 columns)

Lower-left corners are on row 0, upper-right corners on row 1 with a larger x:

| lower-left | valid upper-right corners | rectangles |
|---|---|---|
| (0, 0) | (1, 1), (2, 1), (3, 1) | 3 |
| (1, 0) | (2, 1), (3, 1) | 2 |
| (2, 0) | (3, 1) | 1 |
| (3, 0) | none | 0 |

Total 6.

## Complexity

- **Time: O(n^2)**.
- **Space: O(n)**.

## Alternative: group by column

Group points by x. For every pair of y-values `(y1, y2)` in a column, count how many **previous** columns had the same pair; each such column forms a rectangle with the current one. Add that count, then increment the pair's counter. Also O(n^2) in the worst case, often faster when columns are sparse.

AlgoExpert's reference solution walks clockwise from each point using direction lookups; it is also O(n^2) but more complex. The canonical-diagonal approach is the simplest to get right.

## Sanity check

A 3x3 grid of points contains `C(3,2) * C(3,2) = 9` axis-aligned rectangles (the test checks this).

## Common mistakes

- Counting each rectangle multiple times.
- Treating pairs on the same row or column as diagonals.

## What to remember

To count shapes exactly once, count only a canonical representative (here, the lower-left to upper-right diagonal).
