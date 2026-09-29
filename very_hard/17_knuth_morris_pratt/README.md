# Knuth-Morris-Pratt Algorithm

**Difficulty:** Very Hard | **Category:** Famous Algorithms | **Pattern:** Failure function (longest prefix-suffix) string matching

## Problem
Return whether a substring (pattern) occurs in a string, in O(n + m) time.

## Building up the logic
1. **Naive matching:** try every start position, compare up to m characters: O(n * m). The waste: after a partial match fails, it restarts one position later and **re-reads** characters it already knows.
2. **Insight:** when `j` characters of the pattern have matched and the next one fails, the text's last `j` characters equal `pattern[0..j)`. The next possible match must start at a suffix of that matched part which is also a prefix of the pattern. The longest such overlap is a property of the **pattern alone**, so precompute it.
3. **LPS (failure) array:** `lps[i]` = length of the longest proper prefix of `pattern[0..i]` that is also a suffix of it. Example `aabaaab`: `[0, 1, 0, 1, 2, 2, 3]`.
4. **Matching:** walk the text once. On a mismatch with `j > 0`, set `j = lps[j - 1]` and retry the same text character; never move the text pointer backward. On a match, `j++`; if `j == m`, found.
5. **Building LPS** is the same algorithm run on the pattern against itself.

## Complexity
- Time: O(n + m). The amortized argument: `j` increases at most once per text character, and each fallback decreases it, so total fallbacks are bounded by n.
- Space: O(m) for the LPS array.

## Interview notes
- LeetCode #28 (Find the Index of the First Occurrence). Rarely required to code from scratch at FAANG, but being able to explain the LPS array is a strong signal. The LPS array also answers "shortest palindrome" (#214) and "repeated substring pattern" (#459).
- Alternatives: Rabin-Karp (rolling hash, O(n + m) expected, easy to code), Z-algorithm (same power as KMP).
