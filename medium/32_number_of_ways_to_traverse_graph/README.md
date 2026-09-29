# Number Of Ways To Traverse Graph

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Grid DP / combinatorics

## Problem
In a grid of `width` columns and `height` rows, you start at the top-left cell and must reach the bottom-right cell, moving only right or down. Return the number of distinct paths.

## Building up the logic
1. **Recurrence:** the last move into a cell came from above or from the left, so `ways(r, c) = ways(r-1, c) + ways(r, c-1)`. First row and first column have exactly 1 way.
2. Naive recursion is exponential; tabulation is O(w * h).
3. **Space:** only the previous row is needed, and updating in place left to right works because `row[c]` still holds the "above" value when you read it.
4. **Math:** every path is a sequence of exactly `w - 1` rights and `h - 1` downs. Choose positions for the rights: `C(w + h - 2, w - 1)`. O(min(w, h)) time.

## Complexity
| Approach | Time | Space |
|---|---|---|
| DP table | O(w * h) | O(w * h) |
| Rolling row | O(w * h) | O(w) |
| Binomial coefficient | O(min(w, h)) | O(1) |

## Interview notes
- LeetCode #62. Follow-up #63 adds obstacles: set `ways = 0` on blocked cells. The math formula no longer applies but the DP does. That is why you should know both.
- Overflow: `C(n, k)` grows fast; multiply before dividing (as in the code) so each intermediate stays an exact integer, and mention 64-bit limits.
