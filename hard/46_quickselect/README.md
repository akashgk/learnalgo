# Quickselect

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Partition-based selection

## Problem
Given an array of distinct integers and a positive integer k, return the k-th smallest value (1-based) without fully sorting, in average O(n).

## Building up the logic
1. Sorting: O(n log n). A size-k max-heap: O(n log k). Both fine; the interviewer wants better on average.
2. Quicksort's partition puts the pivot at its **final sorted index** `p`, with smaller elements left and larger right.
3. If `p == k - 1`, done. If `p < k - 1`, the answer is on the right; otherwise on the left. Unlike quicksort, recurse into **one side only**.
4. Expected work: `n + n/2 + n/4 + ... = 2n`, so O(n) on average. Worst case O(n^2) when pivots are consistently bad (sorted input with a fixed first/last pivot). A **random pivot** makes that astronomically unlikely.
5. Iterative loop instead of recursion keeps space O(1).

## Complexity
| Case | Time |
|---|---|
| Average (random pivot) | O(n) |
| Worst | O(n^2) |
| Median-of-medians pivot | O(n) guaranteed (large constant) |

Space: O(1) extra (O(n) here because the input is copied to avoid mutating it).

## Interview notes
- LeetCode #215 (k-th largest = (n - k + 1)-th smallest). Interviewers often accept the heap answer and then ask for quickselect, and then ask about the worst case: say "random pivot or median of medians".
- With many duplicates, use 3-way partitioning (see Three Number Sort) to avoid degrading.
