# Longest Common Subsequence

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 2D string DP with backtracking

## Problem
Given two strings, return their longest common subsequence as a list of characters (a subsequence keeps order but may skip characters). Assume a unique LCS.

```
"ZXVVYZW", "XKYKZPW"  ->  ["X", "Y", "Z", "W"]
```

## Building up the logic
1. **Subproblem:** `L[i][j]` = LCS length of the first `i` chars of `a` and the first `j` chars of `b`.
2. **Recurrence:**
   - if `a[i-1] == b[j-1]`: that character can end the LCS: `L[i][j] = L[i-1][j-1] + 1`;
   - otherwise one of the two last characters is unused: `L[i][j] = max(L[i-1][j], L[i][j-1])`.
3. Base: `L[0][*] = L[*][0] = 0`.
4. **Reconstruct** by walking back from `(n, m)`: on a match take the character and go diagonally; otherwise move toward the larger neighbor. Reverse at the end.
5. Storing whole strings in each cell also works but costs O(n * m * min(n, m)) memory; backtracking over the length table is the efficient approach.

## Complexity
- Time: O(n * m).
- Space: O(n * m) (O(min(n, m)) if you only need the length: keep two rows).

## Interview notes
- LeetCode #1143. The `diff` tool is built on LCS-like algorithms (Myers' diff). Edit distance (Levenshtein) is the sibling DP; compare their recurrences side by side.
