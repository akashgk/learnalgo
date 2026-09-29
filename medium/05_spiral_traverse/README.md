# Spiral Traverse

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Shrinking boundaries (matrix simulation)

## The problem

Given an `n x m` matrix (not necessarily square), return all its elements in **spiral order**: start at the top-left, go right along the top row, down the right column, left along the bottom row, up the left column, then continue with the next inner ring.

```
[[ 1,  2,  3, 4],
 [12, 13, 14, 5],
 [11, 16, 15, 6],
 [10,  9,  8, 7]]   ->  [1, 2, 3, ..., 16]
```

## Step 1: Work an example by hand

Trace the outer ring of the 4x4 example: top row `1 2 3 4`, right column (without the corner already used) `5 6 7`, bottom row right to left (without the corner) `8 9 10`, left column bottom to top (without both corners) `11 12`. That is 12 cells. Now the remaining inner matrix is `[[13, 14], [16, 15]]`, which is the same problem one size smaller.

So think in **rings** (layers). Each ring is described by four boundaries: `top`, `bottom`, `left`, `right`. After a ring, move all four boundaries one step inward.

## Step 2: The algorithm

```
while top <= bottom and left <= right:
    top row:     (top, left..right)
    right col:   (top+1..bottom, right)
    bottom row:  (bottom, right-1..left)     only if top < bottom
    left col:    (bottom-1..top+1, left)     only if left < right
    top++, bottom--, left++, right--
```

### The bug everyone hits

When the last ring is a **single row** or a **single column**, the bottom-row leg would re-read the top row backward, and the left-column leg would re-read the right column upward. The guards `top < bottom` and `left < right` prevent that.

Test on these shapes before claiming your code works: 1x4, 3x1, 3x2, 2x3. The test file includes several.

## Step 3: The code

<!-- CODE:START -->

Full source: [`spiral_traverse.dart`](spiral_traverse.dart) (run it with `dart run`).

```dart
// Spiral Traverse: clockwise from the top-left. Shrink four boundaries after each perimeter.
// O(n) time for n cells, O(n) output.

List<int> spiralTraverse(List<List<int>> matrix) {
  final out = <int>[];
  if (matrix.isEmpty) return out;
  var top = 0, bottom = matrix.length - 1, left = 0, right = matrix[0].length - 1;
  while (top <= bottom && left <= right) {
    for (var c = left; c <= right; c++) {
      out.add(matrix[top][c]);
    }
    for (var r = top + 1; r <= bottom; r++) {
      out.add(matrix[r][right]);
    }
    // Guards stop a single remaining row/column from being traversed twice.
    if (top < bottom) {
      for (var c = right - 1; c >= left; c--) {
        out.add(matrix[bottom][c]);
      }
    }
    if (left < right) {
      for (var r = bottom - 1; r > top; r--) {
        out.add(matrix[r][left]);
      }
    }
    top++;
    bottom--;
    left++;
    right--;
  }
  return out;
}
```

<!-- CODE:END -->

### Walkthrough

- `var top = 0, bottom = ..., left = 0, right = ...;` are the current ring's boundaries (inclusive).
- Leg 1: `for (var c = left; c <= right; c++) out.add(matrix[top][c]);` covers the whole top row including both corners.
- Leg 2: `for (var r = top + 1; r <= bottom; r++)` starts at `top + 1` because the top-right corner was already added.
- Leg 3 (guarded by `top < bottom`): `for (var c = right - 1; c >= left; c--)` starts at `right - 1` because the bottom-right corner was added by leg 2.
- Leg 4 (guarded by `left < right`): `for (var r = bottom - 1; r > top; r--)` excludes both left corners (bottom-left added by leg 3, top-left by leg 1).
- Shrink all four boundaries.

## Step 4: Dry run

3x2 matrix `[[1, 2], [6, 3], [5, 4]]` (expected `1 2 3 4 5 6`):

| ring | top, bottom, left, right | leg 1 | leg 2 | leg 3 (top < bottom?) | leg 4 (left < right?) |
|---|---|---|---|---|---|
| 1 | 0, 2, 0, 1 | 1, 2 | 3, 4 | yes: 5 | yes: r from 1 down to 1: 6 |
| 2 | 1, 1, 1, 0 | loop stops (left > right) | | | |

Output: `[1, 2, 3, 4, 5, 6]`.

Single row `[[1, 2, 3, 4]]`: leg 1 adds all four; leg 2 is empty (`top + 1 > bottom`); leg 3 is skipped because `top == bottom`. Without that guard, it would add `3, 2, 1` again.

## Complexity

- **Time: O(n * m)**: every cell is added exactly once.
- **Space: O(n * m)** for the output; O(1) extra.

## Alternative: direction simulation

Walk cell by cell with a direction vector `(dr, dc)`, turning right when the next cell is outside the matrix or already visited. It needs an O(n * m) `visited` grid (or mutating the input), so the boundary version is preferred.

## Common mistakes

- Missing the single-row / single-column guards (duplicate elements).
- Off-by-one in legs 2 to 4 that re-add corners.
- Assuming the matrix is square.

## Follow-ups

1. **Spiral Matrix II (LeetCode #59):** fill an n x n matrix with 1..n^2 in spiral order. Same boundaries, writing instead of reading.
2. **Spiral Matrix III (#885):** start in the middle and walk outward with growing leg lengths (1, 1, 2, 2, 3, 3, ...).
3. **Recursive version:** process the outer ring, recurse with shrunken boundaries.

## What to remember

Matrix traversals: define the boundaries, process one layer, shrink. Always test degenerate shapes (single row, single column).
