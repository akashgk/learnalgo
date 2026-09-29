# Two Number Sum

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Hash set / Two pointers

## Problem
Given an array of distinct integers and a target sum, return any two numbers from the array that add up to the target. Return an empty array if no pair exists. An element may not be paired with itself.

```
array = [3, 5, -4, 8, 11, 1, -1, 6], target = 10  ->  [11, -1]
```

## Building up the logic
1. **Brute force.** Try every pair `(i, j)` with `i < j`. That is O(n^2). Always state this first in an interview; it proves you understand the problem.
2. **Ask what you are really searching for.** For each `x`, you only need to know whether `target - x` exists. "Does a value exist?" is a lookup question, and lookups are O(1) in a hash set.
3. **Single pass.** Walk the array once. Before inserting `x`, check whether its complement is already in the set. Checking before inserting is what prevents pairing an element with itself.
4. **Space-constrained follow-up.** If the interviewer forbids extra memory, sort and use two pointers: if the sum is too small, the only way to grow it is to move the left pointer right; if too big, move the right pointer left. Each step discards one element that can never be part of an answer.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Hash set (main solution) | O(n) | O(n) |
| Sort + two pointers | O(n log n) | O(1) extra (O(n) here because we copy) |

## Edge cases
- Empty array or single element: no pair.
- Negative numbers and zero work unchanged.
- Duplicates: the problem says distinct; if not, the hash-set version still works because we check before inserting.

## Interview notes
- This is LeetCode #1. Interviewers use it as a warm-up and then push follow-ups: return indices instead of values (use a `Map<int, int>` value -> index), the array is already sorted (two pointers, O(1) space), or find all pairs.
- The two-pointer argument ("moving the pointer discards an element that can never work") is the core proof you will reuse in Three Number Sum and Four Number Sum.
