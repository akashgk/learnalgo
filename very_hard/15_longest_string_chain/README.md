# Longest String Chain

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** DP on a DAG ordered by length

## Problem
Given a list of strings, a chain is a sequence where each string is obtained by removing exactly one character from the previous one, and every string in the chain is in the list. Return the longest chain, starting from its longest string. If there is no chain of at least two strings, return `[]`.

```
["abde", "abc", "abd", "abcde", "ade", "ae", "1abde", "abcdef"]
-> ["abcdef", "abcde", "abde", "ade", "ae"]
```

## Building up the logic
1. Strings and "remove one character" edges form a DAG (edges always go to a shorter string).
2. Longest path in a DAG = DP in topological order. Sorting by length is a valid topological order here.
3. **Subproblem:** `chain[s]` = length of the longest chain starting at `s` and going down.
4. **Transition:** for each of the `m` ways to delete one character from `s`, if the result is in the list, `chain[s] = max(chain[s], chain[shorter] + 1)`. Look up `shorter` in a hash map: O(m) to build the substring and hash it.
5. Store the chosen `shorter` for reconstruction.
6. Generating predecessors (delete one char, O(m) candidates) is much faster than comparing all pairs of strings (O(n^2 * m)).

## Complexity
- Time: O(n log n + n * m^2), where m is the max string length (m deletions, each O(m) to build).
- Space: O(n * m).

## Interview notes
- LeetCode #1048 (Longest String Chain, builds upward by insertion; same DP). A good example of "generate neighbors instead of comparing all pairs".
