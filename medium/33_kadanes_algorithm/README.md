# Kadane's Algorithm

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** DP on "ending at i"

## Problem
Given a non-empty integer array, return the maximum sum of any non-empty contiguous subarray.

## Building up the logic
1. Brute force: all O(n^2) subarrays with a running sum.
2. **Subproblem trick:** instead of "best subarray anywhere in `0..i`", define `E[i]` = best sum of a subarray that **ends exactly at i**. This "ending at i" formulation is the key idea behind many array DPs (LIS, max product subarray).
3. A subarray ending at `i` either is just `[a[i]]`, or extends the best subarray ending at `i - 1`. So `E[i] = max(a[i], E[i-1] + a[i])`. In words: if the running sum became negative, it can only hurt; drop it and restart.
4. The answer is `max(E[i])` over all i.
5. Keep only the previous `E` value: O(1) space.

## Complexity
- Time: O(n).
- Space: O(1).

## Edge cases
- All negative: the answer is the largest single element. Initializing `best = 0` is a classic bug; initialize with `array[0]`.

## Interview notes
- LeetCode #53. Follow-ups: return the indices (track where the current run started), circular array (#918: `max(kadane, total - minSubarray)`, careful when all are negative), max product subarray (#152: track both max and min because a negative flips them), 2D version (Maximum Sum Submatrix / max sum rectangle: fix a pair of rows, run Kadane on column sums, O(r^2 * c)).
