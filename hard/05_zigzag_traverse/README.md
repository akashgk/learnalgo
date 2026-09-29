# Zigzag Traverse

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Anti-diagonal indexing

## Problem
Traverse a 2D array (not necessarily square) in zigzag order: start at the top-left, go down, then move diagonally up-right, then along the edge, then diagonally down-left, and so on until the bottom-right. Return the elements in that order.

```
[[1,  3,  4, 10],
 [2,  5,  9, 11],
 [6,  8, 12, 15],
 [7, 13, 14, 16]]  ->  1..16
```

## Building up the logic
1. Simulating the walk with a "going up / going down" flag and many edge cases (hit top, hit left, hit bottom, hit right) works but is where most bugs happen.
2. **Cleaner view:** all cells with the same `r + c` lie on one anti-diagonal. The traversal visits diagonals `d = 0, 1, 2, ...` in order, alternating direction.
3. Which direction does each diagonal go? Read it off the example instead of guessing: diagonal 1 is `{(0,1)=3, (1,0)=2}` and the output visits 2 before 3, i.e. **bottom to top**. So odd diagonals go up-right (decreasing row) and even diagonals go down-left (increasing row).
4. For diagonal `d`, valid rows are `max(0, d - (cols - 1))` through `min(d, rows - 1)`. Getting these bounds right is the only real work; test on 1xN, Nx1, and non-square inputs.

## Complexity
- Time: O(n), n = total cells.
- Space: O(n) output, O(1) extra.

## Interview notes
- LeetCode #498 (Diagonal Traverse) starts going **up**, so the parity is flipped. Always verify direction on the example rather than assuming.
