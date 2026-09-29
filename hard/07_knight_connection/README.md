# Knight Connection

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** BFS on an implicit infinite graph + a halving argument

## Problem
Two knights stand on an infinite chessboard at given coordinates. Each turn, both knights may move (standard L-shaped knight moves), simultaneously. Return the minimum number of turns until they occupy the same square.

## Building up the logic
1. Only the **relative** position matters. Fix knight A at the origin and ask for the knight-move distance `d` to B's offset.
2. `d` is a shortest path in an unweighted graph (squares are nodes, knight moves are edges): BFS.
3. **Two knights moving together.** Assumption (as in AlgoExpert's version): in each turn, either knight or both may move; a knight may also stay put.
   - Lower bound: one turn changes the knight distance between them by at most 2 (one move each), so at least `ceil(d / 2)` turns are needed.
   - Achievable: take a shortest path of length `d` from A to B. A walks it forward from one end and B walks it backward from the other; they meet at the middle square after `ceil(d / 2)` turns (for odd `d`, one knight rests on the final turn).
   - So the answer is `ceil(d / 2) = (d + 1) ~/ 2`.
4. The board is infinite, so BFS must stop at the target; it always terminates because every square is reachable.

## Complexity
- Time: O(d^2): BFS explores roughly all squares within knight distance d, which is a region of area O(d^2).
- Space: O(d^2) for the visited set.

## Interview notes
- LeetCode #1197 (Minimum Knight Moves) is the single-knight version. Optimizations interviewers like: exploit symmetry (`abs` both coordinates and restrict to a quadrant with a small margin), bidirectional BFS, or the closed-form formula for large distances.
- Dart note: records like `(int, int)` have value equality and hashing, so they work directly in a `Set`.
