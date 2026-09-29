# Common Characters

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Set intersection

## Problem
Given a non-empty list of non-empty strings, return the unique characters that appear in every string, in any order (this solution sorts them for deterministic output).

## Building up the logic
1. A common character must appear in the shortest string, so the shortest string gives the candidate set. This bounds the working set by the smallest string.
2. For each string, intersect the candidates with that string's character set.
3. Alternative: count, for each character, how many strings contain it (dedupe per string), then keep characters whose count equals the number of strings.

## Complexity
- Time: O(n * m) where n is the number of strings and m is the length of the longest string.
- Space: O(c) where c is the number of distinct characters in the shortest string (bounded by the alphabet).

## Interview notes
- LeetCode #1002 is a variant that keeps duplicates (`min` of per-character counts across strings). Clarify which one you are asked: unique characters or with multiplicity.
