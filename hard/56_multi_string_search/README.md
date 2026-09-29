# Multi String Search

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie of patterns, scanned from every text position

## Problem
Given a big string and a list of small strings, return a list of booleans: whether each small string occurs somewhere in the big string.

## Building up the logic
1. **Naive:** for each small string, check every position of the big string: O(b * n * s).
2. **Suffix trie of the big string:** build it (O(b^2)) and look up each small string in O(s). Good when the big string is small and there are many queries.
3. **Trie of the small strings (this code):** build a trie of all small strings (O(n * s)). Then for each start position in the big string, walk the trie as far as the text matches; every word-end node reached is a found small string. A walk stops as soon as the trie has no matching child, and never goes deeper than the longest small string. Total O(b * s).
4. Which trie to build? The one over the **smaller** total input. Stating this trade-off is the insight interviewers look for.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Naive | O(b * n * s) | O(n) |
| Suffix trie of big string | O(b^2 + n * s) | O(b^2) |
| Trie of small strings | O(n * s + b * s) | O(n * s) |
| Aho-Corasick | O(b + n * s + matches) | O(n * s) |

## Interview notes
- Aho-Corasick adds failure links to the pattern trie so the text is scanned once, like KMP for many patterns. It is how `grep -F` and intrusion detection systems work. Name it as the optimal answer.
