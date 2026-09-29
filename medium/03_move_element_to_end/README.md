# Move Element To End

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Two pointers / partitioning

## Problem
Given an array of integers and a value `toMove`, move every occurrence of `toMove` to the end of the array **in place** and return it. The order of the other elements does not matter.

## Building up the logic
1. Sorting is wrong (it moves things by value, not by "is toMove") and O(n log n).
2. This is a two-way partition: "not toMove" on the left, "toMove" on the right. Like the partition step of quicksort.
3. Right pointer `j`: keep moving it left past elements that are already `toMove` (they are in their final region).
4. Left pointer `i`: if `array[i] == toMove`, swap it with `array[j]`, which is guaranteed not to be `toMove`.
5. Stop when the pointers meet.

## Complexity
- Time: O(n): each pointer moves at most n steps.
- Space: O(1).

## Variant: keep relative order (LeetCode #283 "Move Zeroes")
Use a write pointer: copy each non-`toMove` element to `write++`, then fill the rest with `toMove`. Still O(n) / O(1), and stable. Interviewers often ask this variant, so clarify whether order must be preserved.
