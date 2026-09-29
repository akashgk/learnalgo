# Longest Increasing Subsequence

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** Patience sorting (binary search over tails)

## Problem
Return the longest strictly increasing subsequence of an integer array (the subsequence itself, not just its length). Assume a unique answer.

```
[5, 7, -24, 12, 10, 2, 3, 12, 5, 6, 35]  ->  [-24, 2, 3, 5, 6, 35]
```

## Building up the logic
1. **O(n^2) DP:** `L[i]` = length of the LIS ending at i = `1 + max(L[j])` for `j < i` with `a[j] < a[i]`. Store predecessors to rebuild. Always present this first.
2. **Observation:** for each possible length `k`, you only care about the **smallest possible tail value** of an increasing subsequence of length `k`. A smaller tail is always at least as easy to extend.
3. Keep `tails[k]` = (index of) that smallest tail for length `k + 1`. This array is strictly increasing, so it can be binary searched.
4. For each element `x`: find the first `tails` position whose value is `>= x` (lower bound).
   - If there is none, `x` extends the longest subsequence: append.
   - Otherwise `x` becomes a better (smaller) tail for that length: replace.
5. **Reconstruction:** `tails` is **not** the LIS itself (it mixes different subsequences). Record, for each element, the index that was at `tails[pos - 1]` when it was placed; walk back from the last tail.

## Complexity
| Approach | Time | Space |
|---|---|---|
| DP | O(n^2) | O(n) |
| Patience sorting | O(n log n) | O(n) |

## Interview notes
- LeetCode #300. Non-strict (non-decreasing) LIS: use upper bound (`<=`) instead of lower bound.
- Applications: Russian Doll Envelopes (#354), Box Stacking variants, longest chain of pairs.
- A classic trap: printing `tails` as the answer. Explain why it is wrong with `[1, 5, 2]`: tails ends as `[1, 2]`, which happens to be valid, but `[3, 4, 1]` gives tails `[1, 4]`, which is not a subsequence.
