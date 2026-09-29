# Waterfall Streams

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Row-by-row simulation with fractional flow

## Problem
A grid has empty cells (0) and blocks (1). Water is poured at column `source` of the top row and falls downward. When a stream hits a block, it splits into two equal halves, one moving left and one moving right along the row it is in, each continuing sideways until there is an empty cell below it, where it falls again. A half that runs into a block or the edge of the grid while moving sideways is lost. Return, for each column of the bottom row, the percentage of the original water that ends there.

## Building up the logic
1. Water only moves down or sideways, never up, so process the grid **row by row**, carrying a vector of how much water sits in each column.
2. For each column with water in row `r - 1`:
   - if the cell below (row `r`) is empty, the water falls straight down;
   - if it is a block, split in half; each half walks sideways in row `r - 1` until it finds a column whose cell in row `r` is empty (then it falls there) or it hits a block in row `r - 1` / the edge (then it is lost).
3. Different streams can land in the same column; add their amounts.
4. Multiply by 100 at the end.

## Complexity
- Time: O(w^2 * h): each of w columns may walk up to w cells sideways in each of h rows.
- Space: O(w): only two rows of water amounts.

## Interview notes
- Simulation problems are graded on clean state representation. Keep "where the water is" separate from "what the grid looks like"; overloading the grid (e.g. negative numbers for water) works but is harder to reason about.
- State the rules you assume (lost at edges, halves are equal) and confirm them with the interviewer.
