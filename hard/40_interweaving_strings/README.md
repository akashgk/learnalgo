# Interweaving Strings

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** 2D DP over two string prefixes

## Problem
Given strings `one`, `two`, and `three`, return whether `three` can be formed by interweaving `one` and `two`: using all characters of both, preserving the relative order of characters within each.

```
one = "algoexpert", two = "your-dream-job", three = "your-algodream-expertjob"  ->  true
```

## Building up the logic
1. If `len(one) + len(two) != len(three)`, it is impossible.
2. **Recursion:** at state `(i, j)` you have used `i` chars of `one` and `j` chars of `two`, so the next char of `three` is at `k = i + j`. You can advance `i` if `one[i] == three[k]`, or advance `j` if `two[j] == three[k]`. Greedy fails when both match (e.g. `"aab"` vs `"aac"`), so try both.
3. Without memoization this is exponential. There are only `(n + 1) * (m + 1)` distinct states `(i, j)`, so memoize (top-down) or tabulate (bottom-up).
4. **Tabulation:** `ok[i][j]` = prefixes of lengths `i` and `j` can form the prefix of length `i + j`. `ok[i][j] = (ok[i-1][j] && one[i-1] == three[i+j-1]) || (ok[i][j-1] && two[j-1] == three[i+j-1])`.
5. Rolling a single row gives O(m) space.

## Complexity
- Time: O(n * m).
- Space: O(m) with a rolling row (O(n * m) with a full table or memo).

## Interview notes
- LeetCode #97. The step "recursion with overlapping subproblems -> memoize the state tuple" is the general recipe; state it out loud.
