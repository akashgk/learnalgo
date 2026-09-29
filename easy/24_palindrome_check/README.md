# Palindrome Check

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Two pointers

## Problem
Return whether a non-empty string reads the same forwards and backwards.

## Building up the logic
1. Naive: build the reversed string and compare. O(n) time but O(n) extra space. In languages with immutable strings, building it by repeated concatenation is O(n^2), which is worth pointing out.
2. Two pointers: compare first and last, move inward. Stop when they meet. O(1) space.
3. Odd length: the middle character is compared with nothing; `lo < hi` handles it.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- Common follow-ups: ignore non-alphanumerics and case (LeetCode #125), allow deleting one character (LeetCode #680: on the first mismatch, try skipping either side once).
- Unicode caveat: `codeUnitAt` compares UTF-16 code units. For emoji or combining characters, compare `string.runes` or grapheme clusters (`package:characters`). Mentioning this shows production awareness.
