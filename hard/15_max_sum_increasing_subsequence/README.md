# Max Sum Increasing Subsequence

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** LIS-style DP (ending at i) with reconstruction

## Problem
Given a non-empty integer array, find the strictly increasing subsequence (not necessarily contiguous) with the greatest sum. Return `[sum, subsequence]`.

```
[10, 70, 20, 30, 50, 11, 30]  ->  [110, [10, 20, 30, 50]]
```

## Building up the logic
1. **Subproblem:** `S[i]` = greatest sum of an increasing subsequence that **ends at index i** (it must include `a[i]`).
2. **Recurrence:** `S[i] = a[i] + max(S[j])` over `j < i` with `a[j] < a[i]`, or just `a[i]` if no such j (or if all such sums are worse than starting fresh, which matters with negatives).
3. The answer is `max(S[i])`, not `S[n-1]`.
4. **Reconstruction:** store `prev[i]`, the j that achieved the max. Walk back from the best index and reverse.

## Complexity
- Time: O(n^2).
- Space: O(n).

## Interview notes
- This is the Longest Increasing Subsequence template with "sum" instead of "length". Classic LIS has an O(n log n) patience-sorting solution (see Longest Increasing Subsequence, very hard). For max **sum**, an O(n log n) solution exists with a Fenwick tree / segment tree over compressed values (query max sum among values < a[i]); mention it as the scalable version.
- Reconstructing the actual sequence (not only the number) is frequently asked; storing predecessor pointers is the standard technique.
