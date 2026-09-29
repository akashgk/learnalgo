# Underscorify Substring

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Find match intervals, merge, rebuild

## Problem
Given a string and a substring, wrap every occurrence of the substring in underscores. If occurrences overlap or sit right next to each other, wrap the combined region once.

```
"testthis is a testtest to see if testestest it works", "test"
-> "_test_this is a _testtest_ to see if _testestest_ it works"
```

## Building up the logic
1. Split the problem into two clean steps: (a) find all match intervals, (b) insert underscores around merged intervals. Mixing both in one pass is where bugs come from.
2. **Finding matches:** search from every index (advance by 1, not by the match length) so overlapping matches like `testestest` (matches at 0 and 3 and 6) are all found.
3. **Merging:** this is Merge Overlapping Intervals, with "touching" counted as overlapping (`start <= previousEnd`). Matches are found in order, so merging happens on the fly.
4. **Rebuild:** copy unmatched text, then `_` + region + `_`, using a string buffer.

## Complexity
- Time: O(n * m) with naive matching (n = string length, m = substring length). KMP finds all matches in O(n + m).
- Space: O(n).

## Interview notes
- LeetCode #616 / #758 (Add Bold Tag in String) is the multi-keyword version; use a boolean "bold" array or a trie.
- Mention KMP (very hard section) when asked to improve matching.
