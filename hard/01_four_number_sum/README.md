# Four Number Sum

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Pair sums in a hash map (meet in the middle)

## Problem
Given an array of distinct integers and a target, return all quadruplets (in any order) whose values sum to the target. No quadruplet may be repeated.

```
[7, 6, 4, -1, 1, 2], target 16  ->  [[7, 6, 4, -1], [7, 6, 1, 2]]
```

## Building up the logic
1. Brute force O(n^4). Sort + fix two numbers + two pointers: O(n^3), O(1) space. Good baseline, and the natural extension of Three Number Sum.
2. **Meet in the middle:** a quadruplet is two pairs. Store every pair sum in a hash map `sum -> list of pairs`; for each other pair, look up `target - sum`. That is O(n^2) pairs with O(1) lookups.
3. **The hard part is avoiding duplicates and index reuse.** Trick: iterate over a split index `i`.
   - First, for every `j > i`, look up pairs that were registered **before** (both indices `< i`) and combine with `(i, j)`.
   - Then register all pairs `(k, i)` with `k < i`.
   Every quadruplet with sorted indices `p < q < i < j` is found exactly once: when the loop is at `i` (the third smallest index), because the pair `(p, q)` was registered when the loop was at `q`, which is before `i`. At any other split point one of the two pairs is missing. Walk one example by hand to convince yourself.
4. No index is reused because registered pairs only use indices smaller than `i`.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Sort + two pointers | O(n^3) | O(1) extra |
| Pair hash map | O(n^2) average, O(n^3) worst (many pairs share one sum) | O(n^2) |

The worst case of the hash approach comes from the output-like lists stored per sum; mention it.

## Interview notes
- LeetCode #18 allows duplicates in the input; the sort + two pointers version with skip-duplicates logic is the expected answer there.
- LeetCode #454 (4Sum II, four separate arrays, count only) is the clean O(n^2) meet-in-the-middle case.
