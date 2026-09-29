# Rectangle Mania

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Canonical diagonal + point hash set

## Problem
Given distinct 2D points, count the rectangles with sides parallel to the axes whose four corners are all in the set.

```
8 points on two rows (x = 0..3, y = 0..1)  ->  6   (choose any 2 of the 4 columns)
```

## Building up the logic
1. Brute force over 4-point combinations: O(n^4).
2. As in Minimum Area Rectangle, a rectangle is determined by a diagonal. To count each rectangle **exactly once**, only use its lower-left to upper-right diagonal: require `x2 > x1` and `y2 > y1`, and check that `(x1, y2)` and `(x2, y1)` exist.
3. Hash set of points gives O(1) corner checks.

## Alternative (often faster in practice)
Group points by column. For each pair of y-values `(y1, y2)` present in a column, count how many previous columns had the same pair; each forms a rectangle with the current column. Sum `count` over pairs, then increment. Complexity depends on points per column, O(n^2) worst case.

## Complexity
- Time: O(n^2).
- Space: O(n).

## Interview notes
- AlgoExpert's reference solution walks clockwise (up, right, down, left) from each point using direction maps; it is also O(n^2) but more complex. The canonical-diagonal trick is the cleaner way to avoid multiple counting.
- 3x3 lattice sanity check: C(3,2) * C(3,2) = 9 rectangles.
