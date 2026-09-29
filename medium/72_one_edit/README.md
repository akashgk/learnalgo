# One Edit

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Two pointers with a single allowed mismatch

## Problem
Return whether two strings are at most one edit apart, where an edit is inserting, deleting, or replacing one character. (Equal strings are zero edits apart and return true.)

## Building up the logic
1. Levenshtein distance <= 1 works but costs O(n * m). We only need to know if the distance is 0 or 1, which allows O(n).
2. If the lengths differ by more than 1, the answer is false.
3. Walk both strings. At the first mismatch:
   - equal lengths: it must be a replacement; skip the character in both;
   - lengths differ by 1: it must be a deletion from the longer one; skip only in the longer string.
4. A second mismatch means more than one edit.
5. A trailing extra character in the longer string (`"a"` vs `"ab"`) never triggers a mismatch in the loop and is correctly accepted.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #161 (One Edit Distance, which requires exactly one edit, so equal strings return false). Clarify "at most" vs "exactly".
- Cracking the Coding Interview 1.5 is this exact problem.
