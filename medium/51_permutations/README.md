# Permutations

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Backtracking

## Problem
Given an array of distinct integers, return all of its permutations in any order. An empty input returns an empty list.

## Building up the logic
1. Build a permutation position by position. For position 0 there are n choices, for position 1 there are n - 1, and so on: n! leaves in the recursion tree.
2. **Backtracking template:** choose, recurse, un-choose.
3. **Swap version:** the prefix `a[0..i-1]` is fixed. For each `j >= i`, swap `a[j]` into position `i`, recurse on `i + 1`, swap back. This avoids building new lists at every level.
4. **Alternative:** keep a `used` boolean array and a `current` list; append unused elements, recurse, remove.
5. Copy the array when you record a permutation; otherwise every recorded entry points to the same mutated list.

## Complexity
- Time: O(n * n!): n! leaves, O(n) to copy each. (The internal nodes add at most a constant factor: the total number of nodes is about e * n!.)
- Space: O(n * n!) output; O(n) recursion depth.

## Interview notes
- With duplicates (LeetCode #47): sort, and skip a choice if it equals a previous unused choice at the same level (or use a per-level set in the swap version).
- The "choose / recurse / undo" template drives Powerset, Phone Number Mnemonics, N-Queens, Sudoku. Learn it once, reuse it everywhere.
