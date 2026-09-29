# Levenshtein Distance

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** 2D string DP (edit distance)

## Problem
Return the minimum number of single-character edits (insert, delete, substitute) needed to turn one string into another.

```
"abc" -> "yabd"  =  2   (insert 'y', substitute 'c' with 'd')
```

## Building up the logic
1. **Subproblem:** `E[i][j]` = edit distance between the first `i` chars of `a` and the first `j` chars of `b`.
2. **Base cases:** `E[i][0] = i` (delete everything), `E[0][j] = j` (insert everything).
3. **Recurrence:** look at the last characters `a[i-1]` and `b[j-1]`.
   - Equal: no edit needed, `E[i][j] = E[i-1][j-1]`.
   - Different: `1 + min(`
     - `E[i-1][j-1]` (substitute `a[i-1]` with `b[j-1]`),
     - `E[i-1][j]` (delete `a[i-1]`),
     - `E[i][j-1]` (insert `b[j-1]`) `)`.
4. Fill the table row by row. Draw the 4x5 table for `"abc"`/`"yabd"` once by hand; it cements the recurrence.
5. **Space:** each row depends only on the previous row, so keep two rows, sized by the shorter string.

## Complexity
- Time: O(n * m).
- Space: O(min(n, m)) with rolling rows (O(n * m) with the full table, needed if you must reconstruct the edits).

## Interview notes
- LeetCode #72. Close relatives: Longest Common Subsequence, One Edit (the O(n) special case when the answer must be at most 1), Interweaving Strings.
- Real uses: spell checkers, DNA alignment, `git diff` style comparisons. Google interviewers like the "autocorrect" framing.
