# Spiral Traverse

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Shrinking boundaries (matrix simulation)

## Problem
Given an `n x m` matrix, return its elements in clockwise spiral order, starting at the top-left, going right, down, left, up, and continuing inward.

## Building up the logic
1. Think in layers ("perimeters"). Each layer is described by four boundaries: `top`, `bottom`, `left`, `right`.
2. Traverse a layer in four legs: top row left to right; right column downward (skip the corner already visited); bottom row right to left; left column upward (skip both corners).
3. Shrink all four boundaries and repeat while `top <= bottom && left <= right`.
4. **The bug everyone hits:** when the last layer is a single row or single column, the bottom-row and left-column legs retrace cells already visited. Guard them with `top < bottom` and `left < right`. Test with a 1x4, a 3x1, and a 3x2 matrix before declaring done.

## Complexity
- Time: O(n * m), each cell visited once.
- Space: O(n * m) for the output; O(1) extra.

## Alternative
Direction-vector simulation: keep `(dr, dc)`, turn right when the next cell is out of bounds or visited. Needs an O(n * m) visited grid (or in-place marking), so the boundary version is preferred.

## Interview notes
- LeetCode #54. Follow-up: Spiral Matrix II (#59), fill 1..n^2 in spiral order, same boundaries.
