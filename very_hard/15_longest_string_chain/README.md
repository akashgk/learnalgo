# Longest String Chain

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** DP on a DAG processed in length order

## The problem

Given a list of strings, a **string chain** is a sequence where each string is obtained from the previous one by **removing exactly one character**, and every string in the chain is in the list. Return the longest chain, starting from its longest string. If no chain has at least two strings, return `[]`.

```
["abde", "abc", "abd", "abcde", "ade", "ae", "1abde", "abcdef"]
->  ["abcdef", "abcde", "abde", "ade", "ae"]
```

## Step 1: See the graph

Draw an edge from each string to every string obtainable by removing one character (if it is in the list). Every edge goes from a longer string to a shorter one, so there are **no cycles**: it is a DAG. The longest chain is the **longest path** in this DAG.

## Step 2: DP in topological order

In a DAG, the longest path is found with DP in a topological order. Here, sorting the strings by length is a valid topological order (edges always go to strictly shorter strings).

`chain[s]` = the length of the longest chain **starting at s** and going down.

```
chain[s] = 1 + max(chain[s with one character removed])   over removals that are in the list
chain[s] = 1 if no removal is in the list
```

Processing strings from shortest to longest guarantees every shorter string's value is ready.

## Step 3: Generate neighbors instead of comparing pairs

Comparing every pair of strings to check "is one a one-deletion of the other" costs O(n^2 * m). Instead, for each string, **generate** its m one-character deletions and look each up in a hash map: O(m) candidates, O(m) each to build and hash. That is **O(n * m^2)** instead of O(n^2 * m), a big win when n is large.

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_string_chain.dart`](longest_string_chain.dart) (run it with `dart run`).

```dart
// Longest String Chain: a chain goes from a string to a string one character shorter obtained
// by removing one character, and so on, using only given strings. Return the longest chain
// (longest string first); a chain needs at least two strings, else return [].
// Sort by length, DP over removals. O(n * m^2 + n log n) time, O(n * m) space.

List<String> longestStringChain(List<String> strings) {
  final sorted = [...strings]..sort((a, b) => a.length.compareTo(b.length));
  final chainLen = <String, int>{};
  final nextInChain = <String, String?>{};
  for (final s in sorted) {
    chainLen[s] = 1;
    nextInChain[s] = null;
    for (var i = 0; i < s.length; i++) {
      final shorter = s.substring(0, i) + s.substring(i + 1);
      final len = chainLen[shorter];
      if (len != null && len + 1 > chainLen[s]!) {
        chainLen[s] = len + 1;
        nextInChain[s] = shorter;
      }
    }
  }
  String? best;
  for (final s in sorted) {
    if (best == null || chainLen[s]! > chainLen[best]!) best = s;
  }
  if (best == null || chainLen[best]! < 2) return [];
  return [for (String? s = best; s != null; s = nextInChain[s]) s];
}
```

<!-- CODE:END -->

### Walkthrough

- `sorted` orders strings by length.
- `chainLen` and `nextInChain` are maps keyed by the string itself.
- For each string, every deletion `s.substring(0, i) + s.substring(i + 1)` is looked up; the best one becomes `nextInChain[s]`.
- The best starting string is the one with the largest `chainLen`; the chain is rebuilt by following `nextInChain`.

## Step 5: Dry run (values after processing, shortest first)

| string | best deletion in the list | chainLen |
|---|---|---|
| ae | (none) | 1 |
| abc, abd | (none: "ab", "ac", ... not in the list) | 1 |
| ade | ae | 2 |
| abde | ade (or abd) | 3 |
| 1abde | abde | 4 |
| abcde | abde | 4 |
| abcdef | abcde | **5** |

Chain from "abcdef": abcdef -> abcde -> abde -> ade -> ae.

## Complexity

- **Time: O(n log n + n * m^2)**, m = maximum string length.
- **Space: O(n * m)** for the maps.

## Common mistakes

- Processing strings in input order (a longer string may be processed before its shorter predecessor).
- Returning a single-string "chain" instead of `[]`.

## Follow-ups

1. **Longest String Chain (LeetCode #1048):** builds upward by insertion; same DP, returns the length.
2. **Word Ladder (#127):** change one letter per step; BFS on an implicit graph generated the same way (neighbors by modification).

## What to remember

When items form a DAG ordered by size, sort by size and run DP. Generate neighbors (all one-edit variants) and look them up instead of comparing all pairs.
