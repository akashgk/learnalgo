# Next Greater Element

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Monotonic stack (circular)

## Problem
For each element of an array, find the first element to its right that is strictly greater, treating the array as **circular** (after the last element, continue from the first). Use -1 when there is none.

## Building up the logic
1. Brute force: for each i, scan up to n - 1 elements forward (with wrap-around). O(n^2).
2. Maintain a stack of indices still **waiting** for their answer. Their values are non-increasing from bottom to top (if a smaller one were below a bigger one, the bigger one would already have answered it).
3. When a new value arrives, it answers every waiting index whose value is smaller: pop them and record. Then push the new index.
4. **Circularity:** iterate `2n` times with `i = k % n`. The second lap lets elements near the end find answers near the start. Only push during the first lap so each index waits at most once.

## Complexity
- Time: O(n): each index is pushed once and popped at most once.
- Space: O(n).

## How to recognize the pattern
"For each element, the next/previous element that is greater/smaller" -> monotonic stack. Examples: Daily Temperatures (#739), Stock Span (#901), Largest Rectangle in Histogram (#84), Trapping Rain Water (#42, one of several solutions).

## Interview notes
- LeetCode #503. Being able to explain why it is O(n) despite the nested `while` (amortized: each index is popped once) is important.
