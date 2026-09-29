# Valid IP Addresses

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Bounded enumeration / backtracking with pruning

## Problem
Given a string of digits (length at most 12), return every valid IPv4 address you can form by inserting three dots. Each of the four parts must be an integer from 0 to 255 with no leading zeros (`"0"` is fine, `"00"` and `"01"` are not).

## Building up the logic
1. Choose three dot positions. Each part is 1 to 3 digits, so there are at most 3 * 3 * 3 = 27 splits to check.
2. Three nested loops pick the lengths of the first three parts; the fourth part is whatever remains.
3. Validate each part: non-empty, at most 3 digits, no leading zero unless it is exactly `"0"`, value <= 255.
4. Prune early: if the first part is invalid, skip all its inner splits.
5. Backtracking with a `parts` list is the general version (use it if the interviewer changes "4 parts" to "k parts").

## Complexity
- Time: O(1): at most 27 candidate splits, each validated in constant time (input is bounded at 12 characters).
- Space: O(1) (the output has at most 27 entries).

## Interview notes
- LeetCode #93 (Restore IP Addresses). Interviewers check whether you explain why this is O(1). Say "bounded by 3^3 splits because each part is at most 3 digits".
- Edge: strings longer than 12 or shorter than 4 have no answers; you can early-exit.
