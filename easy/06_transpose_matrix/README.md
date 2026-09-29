# Transpose Matrix

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Matrix index mapping

## Problem
Given a 2D integer matrix (at least one row and column), return its transpose: rows become columns, so element `(r, c)` moves to `(c, r)`.

```
[[1, 2],          [[1, 3, 5],
 [3, 4],   ->      [2, 4, 6]]
 [5, 6]]
```

## Building up the logic
1. Output dimensions are swapped: an `h x w` matrix becomes `w x h`.
2. Define each output cell directly: `out[c][r] = in[r][c]`. Thinking "what is the value at this output cell" is cleaner than "where does this input cell go".
3. For a **square** matrix, an in-place transpose swaps `a[i][j]` with `a[j][i]` for `j > i` only (otherwise you swap twice and undo the work). This is step one of "rotate an image 90 degrees" (LeetCode #48).

## Complexity
- Time: O(w * h), every cell is touched once.
- Space: O(w * h) for the new matrix. In-place square version: O(1).

## Edge cases
- Single row or single column (shapes change).
- Non-square input cannot be transposed in place.

## Interview notes
- Get row/column naming right out loud. Most bugs are swapped indices.
- Follow-up: rotate 90 degrees clockwise = transpose then reverse each row.
