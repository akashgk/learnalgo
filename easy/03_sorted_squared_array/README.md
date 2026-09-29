# Sorted Squared Array

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Two pointers from both ends

## Problem
Given an array of integers sorted in ascending order, return a new array containing the squares of each number, also sorted in ascending order.

```
[-7, -3, 1, 9, 22, 30]  ->  [1, 9, 49, 81, 484, 900]
```

## Building up the logic
1. **Naive:** square everything, then sort. O(n log n). Correct, but it ignores the fact that the input is already sorted. When an input is sorted, the interviewer expects you to exploit it.
2. **Where does ordering break?** Squaring is monotonic for non-negatives but reverses order for negatives. So the squared array is "decreasing then increasing" (a valley).
3. **Key observation:** the largest absolute value is always at one of the two ends. So the largest square is at an end.
4. Put pointers at both ends, compare absolute values, write the larger square into the **back** of the result, and move that pointer inward. Filling from the back is the trick: you always know the largest remaining value, never the smallest.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Square + sort | O(n log n) | O(n) |
| Two pointers | O(n) | O(n) for the output (O(1) extra) |

## Edge cases
- All negative, all positive, empty, single zero.
- Overflow: Dart `int` is 64-bit on native, so squares of 32-bit inputs are safe. In Java/C++ mention `long`.

## Interview notes
- LeetCode #977. The "fill from the back" idea reappears in Merge Sorted Array (LeetCode #88).
- Common bug: comparing raw values instead of absolute values.
