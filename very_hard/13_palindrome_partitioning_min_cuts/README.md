# Palindrome Partitioning Min Cuts

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** Palindrome table + prefix DP

## Problem
Return the minimum number of cuts needed to split a string into substrings that are all palindromes.

```
"noonabbad"  ->  2   ("noon" | "abba" | "d")
```

## Building up the logic
1. **Two sub-questions:** (a) is `s[i..j]` a palindrome? (b) given that, what is the fewest cuts for each prefix?
2. **(a) Palindrome table:** `P[i][j] = s[i] == s[j] && P[i+1][j-1]`. O(n^2) time and space. Checking each substring from scratch would make the whole thing O(n^3).
3. **(b) Prefix DP:** `cuts[j]` = min cuts for `s[0..j]`. If `s[0..j]` is a palindrome, 0. Otherwise `cuts[j] = min over i of cuts[i-1] + 1` where `s[i..j]` is a palindrome.
4. **Merge both into one pass (this code):** expand around every center. Each time the expansion confirms `s[lo..hi]` is a palindrome, it immediately relaxes `cuts[hi]` with `cuts[lo-1] + 1`. `cuts[lo - 1]` must already be final when it is read. It is: every palindrome that ends at index `lo - 1` has its center at or before `lo - 1`, which is strictly before the current center, and centers are processed left to right. This removes the O(n^2) table.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Palindrome table + prefix DP | O(n^2) | O(n^2) |
| Center expansion + prefix DP | O(n^2) | O(n) |

## Interview notes
- LeetCode #132. #131 (Palindrome Partitioning) asks for all partitions: backtracking using the same palindrome table.
- Verify the "`cuts[lo-1]` is already final" claim on a small example if asked; interviewers probe it.
