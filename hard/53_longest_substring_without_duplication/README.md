# Longest Substring Without Duplication

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Sliding window with last-seen positions

## Problem
Return the longest substring that contains no repeated characters. Assume a unique answer.

```
"clementisacap"  ->  "mentisac"
```

## Building up the logic
1. Brute force: every substring checked with a set: O(n^3), or O(n^2) with incremental sets.
2. **Sliding window:** maintain a window `[start, i]` with no duplicates. Extend `i` each step. If `s[i]` already appears inside the window, the window must start after that earlier occurrence.
3. Store each character's **last seen index**. On a duplicate, jump `start` directly to `lastSeen + 1` instead of shrinking one character at a time.
4. The guard `prev >= start` is essential: an old occurrence **before** the window must not move `start` backward. Test with `"abba"`: at the final `a`, its previous index 0 is before `start = 2`, so `start` stays.

## Complexity
- Time: O(n).
- Space: O(min(n, alphabet size)).

## Interview notes
- LeetCode #3, possibly the most frequently asked string question at FAANG. The general sliding-window template (expand right, shrink left until valid, record) solves #76 (Minimum Window Substring, see Smallest Substring Containing), #424, #340, #904.
