# Minimum Area Rectangle

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Diagonal pairs + hash set of points

## Problem
Given distinct 2D integer points, return the minimum area of a rectangle with sides parallel to the axes whose four corners are all in the set, or 0 if no such rectangle exists.

## Building up the logic
1. Brute force over 4-point combinations: O(n^4).
2. An axis-aligned rectangle is fixed by one diagonal: `(x1, y1)` and `(x2, y2)` with `x1 != x2` and `y1 != y2`. The other corners must be `(x1, y2)` and `(x2, y1)`.
3. Put all points in a hash set; for each pair, check the two other corners in O(1).
4. Track the smallest area. Each rectangle is found twice (two diagonals), which does not matter for a minimum.

## Alternative
Group points by x-coordinate (columns). For every pair of y-values in a column, remember the last x where that pair was seen; if the same pair appears in a later column, it forms a rectangle whose width is the x difference. O(n^2) worst case, often faster on sparse inputs. This is LeetCode's official approach.

## Complexity
- Time: O(n^2).
- Space: O(n).

## Interview notes
- LeetCode #939. #963 (Minimum Area Rectangle II) allows rotation; there, group pairs by (midpoint, length) of their diagonal.
- Dart records `(x, y)` hash by value, which makes the point set a one-liner.
