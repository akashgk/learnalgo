# Longest Palindromic Substring

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Expand around center

## Problem
Return the longest palindromic substring of a string. Assume a unique answer.

## Building up the logic
1. Brute force: every substring (O(n^2)) checked in O(n): O(n^3).
2. **DP:** `P[i][j]` is true if `s[i] == s[j]` and `P[i+1][j-1]`. O(n^2) time and O(n^2) space. Correct but heavy.
3. **Expand around center:** every palindrome mirrors around its center. There are `2n - 1` centers: each character (odd lengths) and each gap between characters (even lengths). From each center, expand while the ends match. Same O(n^2) time, but O(1) space and simpler.
4. Forgetting even-length centers (`"abba"`) is the classic bug.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^3) | O(1) |
| DP table | O(n^2) | O(n^2) |
| Expand around center | O(n^2) | O(1) |
| Manacher's algorithm | O(n) | O(n) |

## Interview notes
- LeetCode #5. Mention Manacher's algorithm as the O(n) answer; almost no interviewer expects you to code it, but knowing it exists is a plus.
- Related: count all palindromic substrings (#647) uses the exact same expansion; Palindrome Partitioning Min Cuts (very hard) builds on the DP table.
