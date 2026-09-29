# Validate Subsequence

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Two pointers (greedy matching)

## Problem
Given two integer arrays, decide whether the second is a subsequence of the first. A subsequence keeps the original relative order but may skip elements. A single element and the array itself are both valid subsequences.

```
array = [5, 1, 22, 25, 6, -1, 8, 10], sequence = [1, 6, -1, 10]  ->  true
```

## Building up the logic
1. Keep one pointer in `sequence` (what you are waiting for) and scan `array`.
2. Whenever the current array value equals the value you are waiting for, advance the sequence pointer.
3. Why greedy matching is safe: matching a sequence element at the earliest possible position never hurts, because it leaves the largest possible suffix of `array` for the remaining elements. This "earliest match is optimal" argument is the proof, and it is worth saying out loud.
4. At the end, the sequence is valid only if the pointer reached its end.

## Complexity
- Time: O(n), where n is the length of `array`. Each element is visited at most once.
- Space: O(1).

## Edge cases
- Empty `sequence`: trivially true (the problem statement on AlgoExpert says non-empty, but handle it anyway).
- `sequence` longer than `array`: loop ends before the pointer finishes, returns false.
- Repeated values: order matters, e.g. `[1,1,6,1]` vs `[1,1,1,6]` is false.

## Interview notes
- Same technique as LeetCode #392 (Is Subsequence). The follow-up there is "many sequences against the same array": preprocess `array` into value -> sorted list of indices, then binary search for the next index greater than the current one. That gives O(m log n) per query.
