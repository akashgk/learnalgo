# Shortest Unique Prefixes

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie with prefix counts

## Problem
Given a list of strings where no string is a prefix of another, return, for each string, its shortest prefix that is not a prefix of any other string in the list.

```
["zebra", "dog", "duck", "dove"]  ->  ["z", "dog", "du", "dov"]
```

## Building up the logic
1. Brute force: for each string, try prefixes of increasing length and check all other strings. O(n^2 * m^2) naive, O(n^2 * m) with care.
2. **Trie with counts:** insert every string, incrementing a pass-through counter on each node. A prefix is unique iff its node's count is 1.
3. For each string, walk its path from the root and stop at the first node with count 1.
4. The "no string is a prefix of another" assumption guarantees an answer exists; without it, a string like `"do"` next to `"dog"` has no unique prefix (return the whole string or flag it).

## Complexity
- Time: O(n * m) to build and query.
- Space: O(n * m).

## Interview notes
- Classic trie interview question (GeeksforGeeks "shortest unique prefix", used in autocomplete, command-line abbreviations like `git` subcommand matching).
