# Powerset

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Subset generation (iterative doubling / bitmask / backtracking)

## Problem
Given an array of unique integers, return its powerset: every subset, including the empty set, in any order.

## Building up the logic
1. Each element is either in or out of a subset: 2^n subsets.
2. **Iterative doubling:** start with `[[]]`. For each element `x`, take every subset built so far and add a copy with `x` appended. The count doubles each time. Snapshot the count before the inner loop, or you will loop over subsets you just added.
3. **Recursive:** `powerset(a[0..i]) = powerset(a[0..i-1]) + (each of those + a[i])`. Same as step 2.
4. **Backtracking:** at index i, recurse "without a[i]" and "with a[i]".
5. **Bitmask:** numbers `0 .. 2^n - 1` enumerate subsets; bit i says whether `a[i]` is included. Neat, and handy when n <= 20 in DP-over-subsets problems.

## Complexity
- Time: O(n * 2^n): 2^n subsets, average length n/2 to copy.
- Space: O(n * 2^n) output.

## Interview notes
- With duplicates (LeetCode #90): sort, and when `x` equals the previous element, only extend the subsets created in the previous round.
- Knowing that 2^20 is about a million tells you when brute-force subset enumeration is acceptable (n <= ~20).
