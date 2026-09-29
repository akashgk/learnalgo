# Class Photos

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort both, compare pairwise

## Problem
There are equally many students in red and in blue shirts. For a photo you need two rows of equal length where all students in a row wear the same color, and every student in the back row is strictly taller than the student directly in front. Given both height lists, can such a photo be taken?

## Building up the logic
1. Which color goes in the back? The tallest student overall must be in the back row: if they stood in front, the student behind them would have to be even taller, which is impossible. So the color of the tallest student decides the back row. If both tallest are equal, it is impossible.
2. How to pair? Sort both rows descending and pair index by index. Tallest back with tallest front, second with second, etc.
3. **Why sorted pairing is optimal:** if the i-th tallest back student cannot beat the i-th tallest front student, then among the top i back students and top i front students there is a front student no back student in that group can cover (pigeonhole). No arrangement fixes that.
4. Check every pair strictly.

## Complexity
- Time: O(n log n) for sorting.
- Space: O(1) extra with in-place sort (O(n) here because we copy).

## Edge cases
- Equal tallest heights -> false.
- Equal heights at any pair -> false (strictly taller).

## Interview notes
- Mutation: AlgoExpert's reference solution sorts the input in place. Say whether you are allowed to mutate input; copying costs O(n) memory.
- Dart: `final (back, front) = cond ? (red, blue) : (blue, red);` uses a record to pick two values at once.
