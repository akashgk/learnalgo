# Smallest Substring Containing

**Difficulty:** Very Hard | **Category:** Strings | **Pattern:** Variable-size sliding window with counts

## Problem
Given a big string and a small string, return the smallest substring of the big string that contains every character of the small string, including duplicates (if the small string has two `$`, the window needs two `$`). Return `""` if impossible. Assume a unique answer.

```
big = "abcd$ef$axb$c$", small = "$$abf"  ->  "f$axb$"
```

## Building up the logic
1. Brute force: all O(b^2) substrings, each checked in O(b): O(b^3).
2. **Sliding window:** expand `right` until the window contains everything; then shrink `left` as far as possible while it still does, recording the best; then continue expanding.
3. Checking "does the window contain everything?" by comparing maps each time is O(alphabet). Keep a single integer `missing` = required characters (with multiplicity) not yet covered:
   - adding a char whose remaining need is positive decrements `missing`;
   - removing a char whose need becomes positive again increments `missing`.
   The window is valid exactly when `missing == 0`.
4. Letting `need[c]` go negative tracks surplus copies, so removing a surplus copy does not break validity.

## Complexity
- Time: O(b + s): each index enters and leaves the window once.
- Space: O(alphabet).

## Interview notes
- LeetCode #76 (Minimum Window Substring), one of the most asked hard string problems at Meta/Google/Amazon. The `missing` counter trick is what makes the solution clean; practice writing it from memory.
