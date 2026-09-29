# Suffix Trie Construction

**Difficulty:** Medium | **Category:** Tries | **Pattern:** Trie insertion of every suffix

## Problem
Build a suffix trie for a string: a trie containing every suffix, each ending with a special end symbol `*`. Implement `populateSuffixTrieFrom(string)` (done in the constructor here) and `contains(string)`, which returns whether the string is a **suffix** of the original.

```
"babc" suffixes: babc, abc, bc, c
```

## Building up the logic
1. A trie stores strings character by character along paths from the root; shared prefixes share nodes. Each node is a map from character to child.
2. Insert each suffix `string[i..]` starting from the root. The end symbol marks "a suffix ends here", distinguishing suffixes from mere prefixes of suffixes.
3. `contains`: walk the characters; fail on a missing edge; at the end, require the end symbol.
4. Without the end symbol check, `contains` would answer "is it a substring?", which is itself a useful query (every substring is a prefix of some suffix).

## Complexity
- Build: O(n^2) time and space (n suffixes of average length n/2).
- contains: O(m) for a query of length m.

## Interview notes
- Suffix tries answer substring queries in O(m) after preprocessing, which is the basis of Multi String Search (hard section).
- Mention the production-grade structures: suffix **trees** (Ukkonen's algorithm, O(n) build) and suffix **arrays** (O(n log n) build, O(n) space). You are not expected to implement them.
- Dart note: a nested `Map<String, Object>` is a quick trie; a small `TrieNode` class with `Map<String, TrieNode> children` and `bool isEnd` is cleaner for larger problems (see the Tries problems in the hard section).
