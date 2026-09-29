# Search For Range

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Lower bound / upper bound binary search

## Problem
Given a sorted integer array and a target, return `[firstIndex, lastIndex]` of the target, or `[-1, -1]` if absent, in O(log n).

## Building up the logic
1. Binary search for any occurrence, then scan outward: O(n) worst case (all elements equal).
2. Instead, binary search for the **boundaries** directly.
3. **Lower bound:** the first index whose value is `>= x`. Use a half-open interval `[lo, hi)`: if `array[mid] < x`, the answer is to the right (`lo = mid + 1`); otherwise `mid` might be the answer (`hi = mid`). The loop ends with `lo == hi` = the boundary.
4. First occurrence = `lowerBound(target)` (check it actually equals the target). Last occurrence = `lowerBound(target + 1) - 1` (for integers). For non-integers, write `upperBound` with `<=` instead of `<`.
5. Learning one clean `lowerBound` template and deriving everything else from it prevents off-by-one errors.

## Complexity
- Time: O(log n).
- Space: O(1).

## Interview notes
- LeetCode #34. Library equivalents: C++ `lower_bound`/`upper_bound`, Python `bisect_left`/`bisect_right`, Java `Collections.binarySearch` (returns any match, not the first). Dart has `lowerBound` in `package:collection`.
