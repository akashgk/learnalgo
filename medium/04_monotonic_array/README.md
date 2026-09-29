# Monotonic Array

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Single pass with two flags

## Problem
Return whether an integer array is monotonic: entirely non-increasing or entirely non-decreasing. Empty and single-element arrays are monotonic.

## Building up the logic
1. One approach: find the direction from the first pair of unequal elements, then verify the rest. It works but needs care with leading equal elements.
2. Simpler: assume **both** directions are possible and eliminate them as evidence arrives. Any strict decrease kills "non-decreasing"; any strict increase kills "non-increasing".
3. The answer is whether at least one survives. Exit early when both die.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- "Keep all hypotheses alive and eliminate" is a small but reusable trick; it avoids fragile special-casing.
- LeetCode #896.
