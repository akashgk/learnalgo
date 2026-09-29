# Non-Attacking Queens

**Difficulty:** Very Hard | **Category:** Recursion | **Pattern:** Backtracking with O(1) conflict checks (bitmasks)

## Problem
Return the number of ways to place n queens on an n x n chessboard so that no two queens attack each other (no shared row, column, or diagonal).

## Building up the logic
1. Brute force over all placements of n queens among n^2 squares is astronomically large.
2. Each row must contain exactly one queen, so place one queen per row: at most n^n candidates. Each column also has exactly one: at most n! (permutations).
3. **Backtracking:** place a queen in row r in a safe column, recurse to row r + 1, remove it afterwards. Prune as soon as a row has no safe column.
4. **O(1) safety checks:** track blocked columns, blocked "down-right" diagonals (`row - col` constant), and blocked "down-left" diagonals (`row + col` constant) in sets. With **bitmasks**, both diagonal masks shift by one column per row, so the free columns in the current row are `~(cols | diag | antiDiag)`.
5. `free & -free` isolates the lowest free column; iterate until no free columns remain.

## Complexity
- Time: O(n!) upper bound; pruning makes it far smaller in practice (for n = 8 the search tree has 2,057 nodes, versus 40,320 permutations).
- Space: O(n) recursion.

## Interview notes
- LeetCode #51 (return the boards) and #52 (count). The bitmask version is the one that impresses; the set-based version is perfectly acceptable if explained well.
- Known counts: n = 1..8 -> 1, 0, 0, 2, 10, 4, 40, 92.
