# Longest Balanced Substring

**Difficulty:** Very Hard | **Category:** Strings | **Pattern:** Stack of indices, or two counter scans

## Problem
Given a string of `(` and `)`, return the length of the longest substring that is balanced (every opener closed in order).

```
"(()))("  ->  4   ("(())")
```

## Building up the logic
1. Brute force: check every even-length substring with a counter: O(n^3), or O(n^2) with incremental counting.
2. **Stack of indices:** push `-1` as a base. For `(`, push its index. For `)`, pop; if the stack becomes empty, push the current index as the new base (an unmatched `)`); otherwise the current balanced run length is `i - stack.top`. O(n) time and space.
3. **Two counter scans (O(1) space):** scan left to right counting opens and closes. When equal, the prefix since the last reset is balanced: record `2 * close`. When closes exceed opens, the run is broken: reset. This misses runs where opens always exceed closes (e.g. `"(()"`), so repeat the scan right to left with the roles swapped.
4. Each scan alone is insufficient; together they cover every case. Demonstrate with `"(()"`.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) to O(n^3) | O(1) |
| Stack of indices | O(n) | O(n) |
| Two counter scans | O(n) | O(1) |

## Interview notes
- LeetCode #32 (Longest Valid Parentheses). A DP solution (`dp[i]` = length of the valid run ending at i) is a third approach interviewers sometimes ask for.
