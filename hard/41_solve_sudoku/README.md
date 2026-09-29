# Solve Sudoku

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Constraint backtracking

## Problem
Solve a 9x9 Sudoku in place (0 marks an empty cell). Each row, column, and 3x3 box must contain the digits 1-9 exactly once. The puzzle has exactly one solution.

## Building up the logic
1. Backtracking: pick an empty cell, try each digit that does not conflict, recurse to the next empty cell, and undo if the recursion fails.
2. **Validity check cost:** scanning the row, column, and box on every attempt is O(27). Precompute a set of used digits per row, column, and box; then a check is O(1). Bitmasks (`1 << digit`) make the sets tiny and fast; OR them to get all used digits at once.
3. Update the three masks when placing a digit and undo them when backtracking.
4. Precollect the list of empty cells so recursion just advances an index.
5. **Optional heuristic (MRV):** always fill the empty cell with the fewest candidates next. It dramatically prunes the search on hard puzzles; mention it even if you do not implement it.

## Complexity
- Time: exponential in the worst case (at most 9^m for m empty cells), but constraint pruning makes typical puzzles solve in milliseconds.
- Space: O(m) recursion plus O(1) masks (fixed 9x9 board).

## Interview notes
- LeetCode #37 (solve) and #36 (validate). Backtracking skeleton here is the same as N-Queens (Non-Attacking Queens, very hard section).
- For a general exact-cover solver, Knuth's Algorithm X / Dancing Links is the famous technique; name-dropping it is enough.
