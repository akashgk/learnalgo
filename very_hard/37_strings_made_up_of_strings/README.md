# Strings Made Up Of Strings

**Difficulty:** Very Hard | **Category:** Strings | **Pattern:** Word break (DP) accelerated with a trie

## Problem
Given a list of strings and a list of substrings, return the strings (in their original order) that can be formed entirely by concatenating substrings from the list. A substring may be used any number of times.

> Statement note: this is my reconstruction of AlgoExpert's problem from memory (the statement is paywalled). If the site's version forbids reuse or asks for something slightly different, the trie + DP core still applies.

```
strings    = ["bar", "are", "foo", "ba", "b", "barely"]
substrings = ["b", "a", "r", "ba", "ar", "bar", "ely"]
-> ["bar", "ba", "b", "barely"]   ("are" needs an "e" piece; "foo" has no pieces)
```

## Building up the logic
1. For one string, this is **Word Break**: `ok[i]` = the prefix of length i can be built; `ok[0] = true`; `ok[j] = true` if some `ok[i]` is true and `s[i..j)` is a substring piece.
2. Checking every `(i, j)` pair with a hash set costs O(m^2) substring constructions of length up to m: O(m^3) per string.
3. **Trie of substrings:** from each reachable position `i`, walk the trie along `s`. Every word-end node you pass marks `ok[k + 1]`. The walk stops when the trie has no matching child, and never goes deeper than the longest substring L.
4. Build the trie once and reuse it for all strings.

## Complexity
- Time: O(total substring length) to build the trie + O(m * L) per string of length m.
- Space: O(total substring length) for the trie, O(m) per DP.

## Interview notes
- LeetCode #139 (Word Break) and #472 (Concatenated Words, where the dictionary and the strings are the same list: sort by length and add each word to the trie after checking it).
