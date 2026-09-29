# Group Anagrams

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Canonical key + hash map grouping

## Problem
Given a list of words, group together words that are anagrams of each other (same letters, any order). Return the groups in any order.

## Building up the logic
1. Comparing every pair for anagram-ness is O(w^2 * n).
2. Anagrams share a **canonical form**. Map each word to a key that is identical for all its anagrams and different otherwise, then group by key in a hash map.
3. Key options:
   - sorted letters: `"act"` for `act`, `tac`, `cat`. O(n log n) per word.
   - letter counts: a 26-length count vector serialized as a string (`"1#0#1#..."`). O(n) per word. Use a separator so counts like 1,11 vs 11,1 do not collide.

## Complexity
- Time: O(w * n log n) with sorted keys; O(w * n) with count keys (w words, n = max length).
- Space: O(w * n).

## Interview notes
- LeetCode #49. The "canonical key" idea generalizes: group shifted strings (#249, key = differences between consecutive letters), isomorphic strings, equivalent fractions.
- Dart note: `(groups[key] ??= []).add(word)` is the idiomatic "get or create then append".
