# Minimum Characters For Words

**Difficulty:** Medium | **Category:** Strings | **Pattern:** Per-key maximum of frequency maps

## Problem
Given a list of words, return the smallest list of characters (with repeats) such that **each** word, individually, can be spelled using characters from the list. Words are not spelled at the same time, so characters are reused across words.

```
["this", "that", "did", "deed", "them!", "a"]
-> t, t, h, i, s, a, d, d, e, e, m, !   (any order)
```

## Building up the logic
1. Because words are formed one at a time, you need, for each character, as many copies as the single most demanding word needs, not the sum across words.
2. Count each word's characters; merge into a global map by taking the **maximum** per character.
3. Expand the map into a list.

## Complexity
- Time: O(n * l), n words of max length l.
- Space: O(c), distinct characters.

## Interview notes
- Sum vs max is the entire question. Say it explicitly: "each word individually, so max, not sum."
- Related: LeetCode #916 (Word Subsets) uses the same max-merge of counts.
