# Reveal Minesweeper

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Flood fill with a stopping condition

## Problem
A Minesweeper board contains `'M'` (hidden mine), `'H'` (hidden safe cell), or already-revealed digits. Given the cell a player clicks:
- If it is a mine, replace it with `'X'` and return.
- Otherwise reveal it as the number of mines among its 8 neighbors. If that number is 0, also reveal all hidden neighbors by the same rules (cascading).

## Building up the logic
1. This is flood fill, but the fill **stops** at cells that have at least one adjacent mine (they get revealed but do not spread).
2. Neighbors are the 8 surrounding cells, not 4. Enumerate with `dr, dc in {-1, 0, 1}` excluding `(0, 0)`, with bounds checks.
3. Use the board itself as the visited marker: only process cells that are still `'H'`.
4. An explicit stack avoids deep recursion on a large empty board.

## Complexity
- Time: O(w * h): each cell is revealed at most once and checks 8 neighbors.
- Space: O(w * h) for the stack in the worst case.

## Interview notes
- LeetCode #529 (Minesweeper). Related: generating a board (random mine placement with Fisher-Yates) and the "first click is never a mine" rule are common object-oriented design follow-ups.
- Dart note: `sync*` generator with `yield` produces neighbor coordinates lazily; records `(int, int)` access fields via `.$1` and `.$2`.
