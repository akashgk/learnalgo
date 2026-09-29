# Index Equals Value

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Binary search on a derived monotonic function

## Problem
Given a sorted array of **distinct** integers, return the smallest index `i` such that `array[i] == i`, or -1 if none exists.

## Building up the logic
1. Linear scan: O(n).
2. Define `f(i) = array[i] - i`. Because values are distinct integers and sorted, `array[i+1] >= array[i] + 1`, so `f(i+1) >= f(i)`: **f is non-decreasing**.
3. We want the first `i` with `f(i) == 0`. That is a lower-bound binary search on `f`:
   - `f(mid) < 0`: all indices left of mid also have `f < 0`; go right.
   - `f(mid) >= 0`: the first zero (if any) is at mid or to the left; record mid if it is a zero and go left.
4. The "distinct" condition is essential. With duplicates (`[2, 2, 2]`), `f` is no longer monotonic and you need a different approach (skip-ahead recursion, worst case O(n)).

## Complexity
- Time: O(log n).
- Space: O(1).

## Interview notes
- Cracking the Coding Interview 8.3 (Magic Index). The general lesson: binary search works on any **monotonic predicate**, not just on raw sorted values. Search over answers ("smallest capacity that works") is the same idea.
