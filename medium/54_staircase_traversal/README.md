# Staircase Traversal

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** DP with a sliding window sum

## Problem
Given a staircase `height` and the maximum number of steps you can take at once (`maxSteps`), return the number of distinct ways to reach the top. Order matters (1+2 and 2+1 are different).

## Building up the logic
1. The last move lands on `height` from one of `height - 1, ..., height - maxSteps`. So `ways(h) = ways(h-1) + ... + ways(h-maxSteps)`, with `ways(0) = 1` and negatives = 0. With `maxSteps = 2` this is Fibonacci.
2. Plain recursion: O(k^n). Memoization or tabulation: O(n * k).
3. **Sliding window:** consecutive `ways(h)` share all but two terms. Maintain a running sum: add the newest value, subtract the one that fell out of the window. O(n).

## Complexity
| Approach | Time | Space |
|---|---|---|
| Recursion | O(k^n) | O(n) |
| Memo / table | O(n * k) | O(n) |
| Sliding window | O(n) | O(n) (O(k) with a circular buffer) |

## Interview notes
- LeetCode #70 (Climbing Stairs) is the `maxSteps = 2` case. The sliding window sum trick shows up again in "number of ways to roll dice to reach target" style problems (see Dice Throws).
