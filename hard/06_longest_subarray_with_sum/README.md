# Longest Subarray With Sum

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Sliding window (non-negative) / prefix-sum map (general)

## Problem
Given an array of **non-negative** integers and a target sum, return `[start, end]` of the longest contiguous subarray whose sum equals the target, or `[]` if none exists.

```
[1, 2, 15, 3, 4, 5, 6, 7, 8], target 30  ->  [0, 5]   ([4, 8] also sums to 30 but is shorter)
```

## Building up the logic
1. Brute force: all subarrays with a running sum, O(n^2).
2. **Why a sliding window works here:** with non-negative numbers, extending the window never decreases the sum and shrinking never increases it. So for each right end, there is a single left boundary to maintain, and it only moves forward.
3. Expand `right`; while the sum exceeds the target, shrink from the left; when it equals the target, compare lengths.
4. Zeros matter: `[0, 0, 5, 0, 0]` with target 5 is the whole array. The window naturally keeps leading zeros because it only shrinks when the sum is too big.
5. **General case (negatives allowed):** the monotonicity argument breaks. Use prefix sums: a subarray `(i, j]` sums to target iff `P[j] - P[i] = target`. Store the **first** index of each prefix sum (first, to maximize length) and look up `P[j] - target`.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Sliding window (non-negative only) | O(n) | O(1) |
| Prefix sum map (any sign) | O(n) | O(n) |

## Interview notes
- Say why the sliding window is valid (monotonic sum). Interviewers often change the constraint to allow negatives to test whether you know the limitation.
- Related: LeetCode #325 (Maximum Size Subarray Sum Equals k), #560 (count of subarrays), #209 (minimum length with sum >= target, sliding window).
