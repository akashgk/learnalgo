# First Non-Repeating Character

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Frequency map, two passes

## Problem
Given a string of lowercase letters, return the index of the first character that appears exactly once, or -1 if none does.

## Building up the logic
1. Brute force: for each index, scan the whole string for a duplicate. O(n^2).
2. The question "how many times does c occur?" is asked repeatedly, so precompute it: one pass to count, one pass (in original order) to find the first count of 1.
3. Why two passes and not one? Order matters and counts are only final after the full scan.

## Complexity
- Time: O(n).
- Space: O(1): at most 26 keys for lowercase letters. Say "O(1) because the alphabet is bounded"; interviewers want to hear the justification, not just "O(1)".

## Interview notes
- Streaming follow-up (characters arrive one by one, answer after each): keep counts plus a queue (or a linked hash set) of candidates; pop from the front while the front's count exceeds 1. Amortized O(1) per character.
- LeetCode #387.
