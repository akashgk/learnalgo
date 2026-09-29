# Count Squares

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Geometry + hash set of points (fix a diagonal)

## The problem

Given a list of distinct 2D integer points, return the number of squares whose four corners are all in the list. Squares can be **rotated**; they do not have to be aligned with the axes.

```
[[1, 1], [0, 0], [-4, 2], [-2, -1], [0, 1], [1, 0], [-1, 4]]  ->  2
```

One square is the unit square `(0,0), (1,0), (1,1), (0,1)`. The other is a rotated square `(-4,2), (-2,-1), (1,1), (-1,4)`.

## Step 1: Brute force

Check every group of 4 points: **O(n^4)**, with a geometric test for "is this a square".

## Step 2: A square is determined by one diagonal

Take two opposite corners A and B. The other two corners are fixed:

- the **center** is the midpoint `M = (A + B) / 2`;
- the **half-diagonal** vector is `v = A - M`;
- the other two corners are `M` plus/minus `v` rotated by 90 degrees. Rotating `(x, y)` by 90 degrees gives `(-y, x)`.

So `C = M + (-v.y, v.x)` and `D = M + (v.y, -v.x)`.

Check with the unit square: A = (0, 0), B = (1, 1). M = (0.5, 0.5), v = (-0.5, -0.5). C = (0.5 + 0.5, 0.5 - 0.5) = (1, 0). D = (0.5 - 0.5, 0.5 + 0.5) = (0, 1). Correct.

## Step 3: Algorithm

1. Put all points in a hash set.
2. For every pair (A, B), compute C and D and check both in the set: O(1).
3. Each square has **two** diagonals, so it is found twice: divide the count by 2.

O(n^2) pairs, O(1) each: **O(n^2)**.

## Step 4: The precision trap

The midpoint can be a half-integer (0.5 above). Floating point works for small inputs but risks rounding errors and hash mismatches. The code avoids fractions entirely by **doubling every coordinate** first. Then the midpoint of two doubled points is always an integer, and all arithmetic stays exact.

## Step 5: The code

<!-- CODE:START -->

Full source: [`count_squares.dart`](count_squares.dart) (run it with `dart run`).

```dart
// Count Squares: number of squares (any rotation) whose 4 corners are among the points.
// For each pair treated as a diagonal, compute the other two corners and check the set.
// Each square is found twice (two diagonals). Doubled coordinates avoid fractions.
// O(n^2) time, O(n) space.

int countSquares(List<List<int>> points) {
  final set = {for (final [x, y] in points) (2 * x, 2 * y)};
  final p = [for (final [x, y] in points) (2 * x, 2 * y)];
  var count = 0;
  for (var i = 0; i < p.length; i++) {
    for (var j = i + 1; j < p.length; j++) {
      final (x1, y1) = p[i];
      final (x2, y2) = p[j];
      final mx = (x1 + x2) ~/ 2, my = (y1 + y2) ~/ 2; // exact: coordinates are doubled
      final dx = x1 - mx, dy = y1 - my; // half-diagonal vector
      final c = (mx - dy, my + dx), d = (mx + dy, my - dx); // rotate by 90 degrees
      if (set.contains(c) && set.contains(d)) count++;
    }
  }
  return count ~/ 2;
}
```

<!-- CODE:END -->

### Walkthrough

- Both the set and the list store doubled coordinates as records.
- For each pair: midpoint `(mx, my)`, half-diagonal `(dx, dy) = A - M`, and the two rotated corners `c` and `d`.
- `count ~/ 2` corrects for counting each square once per diagonal.

## Step 6: Dry run (unit square only, doubled coordinates)

Points doubled: (0, 0), (2, 0), (2, 2), (0, 2).

| pair (diagonal) | midpoint | other corners | both present? |
|---|---|---|---|
| (0,0)-(2,2) | (1,1) | (2,0), (0,2) | yes |
| (2,0)-(0,2) | (1,1) | (2,2), (0,0) | yes |
| side pairs like (0,0)-(2,0) | (1,0) | (1,-1), (1,1) | no |

2 hits / 2 = 1 square.

## Complexity

- **Time: O(n^2)**.
- **Space: O(n)** for the set.

## Alternative: fix a side instead of a diagonal

For each pair treated as a **side**, there are two possible squares (one on each side of the segment). Check both. Each square is then counted 4 times (once per side).

## Common mistakes

- Using floating point without care.
- Forgetting to divide by 2 (or 4 for the side version).
- Only counting axis-aligned squares.

## Sanity check

A 3x3 grid of points contains 6 squares: four 1x1, one 2x2, and one tilted square whose corners are the midpoints of the outer edges. The test file checks exactly this.

## Follow-ups

1. **Detect Squares (LeetCode #2013):** axis-aligned, points added over time; count with a hash map of point frequencies.
2. **Valid Square (#593):** given 4 points, check the 6 pairwise distances (4 equal sides, 2 equal diagonals).
3. **Minimum Area Rectangle (very hard 04)** and **Rectangle Mania (very hard 19):** the same "fix a diagonal" idea for rectangles.

## What to remember

A square (or rectangle) is determined by one diagonal. Enumerate pairs as diagonals, compute the missing corners, and look them up in a hash set. Keep geometry in exact integers.
