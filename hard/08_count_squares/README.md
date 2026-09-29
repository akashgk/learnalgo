# Count Squares

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Geometry + hash set of points (fix a diagonal)

## Problem
Given a list of distinct 2D integer points, return how many squares can be formed with their corners at these points. Squares may be rotated (not axis-aligned).

## Building up the logic
1. Brute force: all 4-point combinations, O(n^4).
2. A square is determined by one of its **diagonals**. Given diagonal endpoints `A` and `B`, the midpoint `M = (A + B) / 2` and half-diagonal `v = A - M`. The other two corners are `M` plus/minus `v` rotated by 90 degrees: `M + (-v.y, v.x)` and `M + (v.y, -v.x)`.
3. For each pair of points (O(n^2)), compute the other two corners and check both in a hash set (O(1)).
4. Each square has two diagonals, so it is counted twice: divide by 2.
5. **Precision:** the midpoint can be a half-integer. Double every coordinate up front so all arithmetic stays in exact integers. Floating point with rounding is a common source of bugs and hash mismatches.

## Complexity
- Time: O(n^2).
- Space: O(n).

## Alternative
Fix a **side** instead of a diagonal: for each pair, rotate the side vector to get two possible squares (one on each side). Each square is then counted 4 times.

## Interview notes
- The 3x3 lattice contains 6 squares: four 1x1, one 2x2, and one tilted square with corners at the edge midpoints. That is a good sanity test.
- LeetCode #2013 (Detect Squares) is the axis-aligned streaming version.
