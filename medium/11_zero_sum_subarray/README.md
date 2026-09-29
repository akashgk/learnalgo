# Zero Sum Subarray

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Prefix sums + hash set

## Problem
Given an integer array, return whether some non-empty contiguous subarray sums to zero.

## Building up the logic
1. Brute force: all O(n^2) subarrays, each summed in O(1) if you extend a running sum. O(n^2).
2. **Prefix sums:** let `P[k]` be the sum of the first k elements (`P[0] = 0`). The sum of `nums[i..j]` is `P[j+1] - P[i]`.
3. So a zero-sum subarray exists iff two prefix sums are equal.
4. "Have I seen this value before?" is a hash-set question. Seed the set with 0 for the empty prefix; that is what catches subarrays starting at index 0 (including a single 0).

## Complexity
- Time: O(n).
- Space: O(n).

## Interview notes
- This is the most important array technique for subarray-sum questions. Generalizations:
  - Subarray sum equals k (LeetCode #560): look for `sum - k` in a **map of counts**.
  - Longest subarray with sum k (Longest Subarray With Sum, hard in this repo): map prefix sum -> **first** index.
  - Subarray sum divisible by k (#974): use `sum % k` as the key.
- Sliding window does **not** work here because of negative numbers. Explain why: with negatives, shrinking the window does not monotonically decrease the sum.
