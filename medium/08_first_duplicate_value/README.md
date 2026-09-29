# First Duplicate Value

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Index-as-hash (sign marking)

## Problem
Given an array of length n whose values are all in `[1, n]`, return the first value that appears twice when reading left to right (the one whose **second** occurrence comes earliest). Return -1 if there is none. You may mutate the input.

```
[2, 1, 5, 2, 3, 3, 4]  ->  2
[2, 1, 5, 3, 3, 2, 4]  ->  3   (second 3 at index 4 comes before second 2 at index 5)
```

## Building up the logic
1. Brute force: for each element, search for an earlier equal element. O(n^2), O(1).
2. Hash set of seen values: return the first value already in the set. O(n), O(n). This is already a good answer.
3. The constraint "values in [1, n]" is the hint: every value maps to a valid index `value - 1`. The array itself can be the "seen" set.
4. Mark value `v` as seen by making `array[v - 1]` negative. Because elements may already be negated, always read `abs()`.
5. The first time you find `array[v - 1]` already negative, `v` is the answer.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Hash set | O(n) | O(n) |
| Sign marking | O(n) | O(1) |

## Interview notes
- Say out loud that sign marking mutates input, and offer to restore it (as this code does). Mutating input silently is a red flag in production code reviews.
- Same family: LeetCode #442 (Find All Duplicates), #448 (Find All Missing), #41 (First Missing Positive), #287 (Find the Duplicate Number, where mutation is forbidden: use Floyd's cycle detection).
