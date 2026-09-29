# Sweet And Savory

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Split + sort + two pointers

## Problem
Dishes have non-zero integer flavor values: negative means sweet, positive means savory. Pick exactly one sweet and one savory dish so that their sum is as close as possible to `target` **without exceeding it**. Return `[sweet, savory]`, or `[0, 0]` if no valid pair exists. Assume at most one best pair.

## Building up the logic
1. Brute force: every sweet with every savory, O(s * v).
2. This is Smallest Difference with a one-sided constraint (sum <= target), across two groups. Split the dishes into the two groups.
3. Order each group so that one pointer increases the sum and the other decreases it:
   - sweets from closest-to-zero outward (`-1, -3, -5`): moving `i` makes the sum **smaller**;
   - savories ascending (`1, 2, 7`): moving `j` makes the sum **larger**.
4. If the sum fits (<= target), record it and move `j` to try a larger sum. If it exceeds target, move `i` to shrink it.
5. Each move discards one element that cannot produce a better valid pair with remaining partners, so the scan is linear.

## Complexity
- Time: O(n log n) for sorting.
- Space: O(n) for the two groups.

## Interview notes
- Strong candidates reduce new-looking problems to known ones out loud: "this is two-pointer closest-sum on two sorted lists." Practice saying the reduction.
