# Minimum Area Rectangle

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Diagonal pairs + hash set of points

## The problem

Given distinct 2D integer points, return the **minimum area** of a rectangle with sides **parallel to the axes** whose four corners are all in the set. Return 0 if no such rectangle exists.

```
[[1, 5], [5, 1], [4, 2], [2, 4], [2, 2], [1, 2], [4, 5], [2, 5], [-1, -2]]  ->  3

The rectangle with corners (1, 2), (2, 2), (1, 5), (2, 5): width 1, height 3.
```

## Step 1: Brute force

All 4-point combinations: **O(n^4)**.

## Step 2: One diagonal determines the rectangle

For an axis-aligned rectangle, if you know two **opposite** corners `(x1, y1)` and `(x2, y2)` (with `x1 != x2` and `y1 != y2`), the other two corners are forced: `(x1, y2)` and `(x2, y1)`.

So for each pair of points, treat it as a diagonal and check whether the two other corners exist. With the points in a **hash set**, each check is O(1). **O(n^2)** overall.

Each rectangle is found twice (once per diagonal), which does not matter when looking for a minimum.

## Step 3: The code

<!-- CODE:START -->

Full source: [`minimum_area_rectangle.dart`](minimum_area_rectangle.dart) (run it with `dart run`).

```dart
// Minimum Area Rectangle (axis-aligned) from a set of points; 0 if none.
// Treat each pair as a diagonal; the other two corners must exist. O(n^2) time, O(n) space.

int minimumAreaRectangle(List<List<int>> points) {
  final set = {for (final [x, y] in points) (x, y)};
  int? best;
  for (var i = 0; i < points.length; i++) {
    final [x1, y1] = points[i];
    for (var j = i + 1; j < points.length; j++) {
      final [x2, y2] = points[j];
      if (x1 == x2 || y1 == y2) continue; // not a diagonal
      if (set.contains((x1, y2)) && set.contains((x2, y1))) {
        final area = (x1 - x2).abs() * (y1 - y2).abs();
        if (best == null || area < best) best = area;
      }
    }
  }
  return best ?? 0;
}
```

<!-- CODE:END -->

### Walkthrough

- The set stores points as `(x, y)` records, which hash by value.
- Pairs sharing an x or a y cannot be diagonals; skip them.
- For valid diagonals, check the two corners and update the smallest area.
- `best ?? 0` returns 0 when no rectangle was found.

## Step 4: Dry run (the winning pair)

Take `(1, 2)` and `(2, 5)` as a diagonal. The other corners are `(1, 5)` and `(2, 2)`: both in the set. Area `|1 - 2| * |2 - 5| = 3`. Other rectangles, such as `(1, 2), (4, 2), (1, 5), (4, 5)` with area 9, are larger.

## Complexity

- **Time: O(n^2)**.
- **Space: O(n)** for the set.

## Alternative: group by column

Group points by x. For every pair of y-values `(y1, y2)` in a column, remember the last x where that pair appeared. If a later column has the same pair, those two columns form a rectangle with width equal to the x difference and height `y2 - y1`. Worst case still O(n^2), often much faster on sparse inputs. This is the approach in LeetCode's official solution.

## Common mistakes

- Treating pairs on the same row or column as diagonals (zero area).
- Floating-point points or tuples that do not hash by value (in some languages you must encode the point as a string or a long).

## Follow-ups

1. **Minimum Area Rectangle (LeetCode #939).**
2. **Minimum Area Rectangle II (#963):** rotation allowed. Group pairs by (midpoint, length) of their diagonal: two pairs with the same midpoint and length are the diagonals of a rectangle.
3. **Count all rectangles:** Rectangle Mania (very hard 19).

## What to remember

A rectangle is determined by one diagonal; enumerate pairs as diagonals and look up the missing corners in a hash set.
