# Generate Document

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Frequency counting

## Problem
Given a string of available characters and a document string, return whether the document can be generated, using each available character at most once. Case and whitespace matter. An empty document can always be generated.

## Building up the logic
1. Brute force: for each distinct document character, count it in both strings. O(m * (n + m)).
2. Better: count each available character once into a hash map (or a 256/65536 array), then walk the document and decrement. If any count would go negative, fail.
3. Early exit: if `document.length > characters.length`, return false immediately.

## Complexity
- Time: O(n + m) (n = characters, m = document).
- Space: O(c) where c is the number of distinct characters.

## Interview notes
- LeetCode #383 (Ransom Note). With a known small alphabet, a fixed-size `List<int>` of counts is faster than a map, and interviewers like hearing that trade-off.
