# Find Three Largest Numbers

**Difficulty:** Easy | **Category:** Searching | **Pattern:** Running top-k

## Problem
Given an array of at least three integers, return the three largest in ascending order, without sorting the input. Duplicates count separately (`[10, 5, 9, 10, 12]` -> `[10, 10, 12]`).

## Building up the logic
1. Keep a fixed 3-slot array, slot 2 the largest.
2. For each number, find the highest slot it beats (starting from the largest). If it beats slot `i`, everything below `i` shifts down one place and the number goes into slot `i`.
3. Using `null` for "empty slot" avoids sentinel bugs with negative inputs (initializing with 0 would break `[-1,-2,-3]`).
4. Strict `>` means an equal value lands in a lower slot, which is how duplicates are kept.

## Complexity
- Time: O(n) (the inner work is bounded by the constant 3).
- Space: O(1).

## Generalization: top-k
For arbitrary k, keep a **min-heap of size k**: push each element, pop when size exceeds k. O(n log k) time, O(k) space. Quickselect finds the k-th largest in O(n) average. Both are standard FAANG follow-ups (LeetCode #215).
