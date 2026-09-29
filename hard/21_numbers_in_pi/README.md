# Numbers In Pi

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Word break (min pieces)

## Problem
Given a string of pi's digits and a list of "favorite numbers" (strings of digits), insert the minimum number of spaces into the pi string so that every resulting piece is a favorite number. Return that minimum, or -1 if impossible.

```
pi = "3141592653589793238462643383279"
favorites = ["314159265358979323846", "26433", "8", "3279", "314159265", "35897932384626433832", "79"]
-> 2   ("314159265 35897932384626433832 79")
```

## Building up the logic
1. This is LeetCode Word Break with "minimize pieces" instead of "is it possible".
2. **Subproblem:** `best[i]` = minimum pieces to split the suffix starting at `i`; `best[n] = 0`.
3. **Recurrence:** for every `end > i` with `pi[i..end)` a favorite, `best[i] = min(best[end] + 1)`.
4. Fill from right to left. The answer is `best[0] - 1` spaces (pieces minus one), or -1 if unreachable.
5. Store favorites in a hash set for O(1) membership (after the O(length) substring hash).

## Complexity
- Time: O(n^3) in the worst case: O(n^2) (i, end) pairs, each building and hashing a substring of length up to n. Bounding `end - i` by the longest favorite reduces it to O(n * L^2). A trie of favorites walked from each i gives O(n * L).
- Space: O(n + m).

## Interview notes
- LeetCode #139 (Word Break) and #140 (Word Break II, return all splits via memoized backtracking). Mentioning the trie optimization is a good depth signal.
