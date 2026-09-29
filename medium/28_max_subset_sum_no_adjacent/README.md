# Max Subset Sum No Adjacent

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Linear DP (take / skip)

## Problem
Given an array of positive integers, return the maximum sum of a subset with no two elements adjacent in the array. Return 0 for an empty array.

```
[75, 105, 120, 75, 90, 135]  ->  330   (75 + 120 + 135)
```

## Building up the logic
1. Brute force: all subsets without adjacency, exponential.
2. **Define the subproblem:** `best[i]` = max sum using only elements `0..i`.
3. **Recurrence (choice at i):**
   - skip `a[i]`: `best[i-1]`
   - take `a[i]`: then `a[i-1]` is excluded, so `best[i-2] + a[i]`
   - `best[i] = max(best[i-1], best[i-2] + a[i])`
4. **Base cases:** `best[0] = a[0]`, `best[1] = max(a[0], a[1])`. Using two zero-initialized variables handles these automatically.
5. **Space optimization:** each state depends only on the previous two, so keep two variables.

## Complexity
- Time: O(n).
- Space: O(1) (O(n) with the full table).

## How to recognize this pattern
"Choose elements, each choice forbids neighbors, maximize sum" -> take/skip linear DP.

## Interview notes
- LeetCode #198 (House Robber). Follow-ups: #213 (circular street: run twice, excluding the first or the last house), #337 (houses on a binary tree: return `(robThis, skipThis)` from each subtree).
