# Radix Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Non-comparison sort (digit by digit with counting sort)

## Problem
Sort an array of non-negative integers using Radix Sort.

## Building up the logic
1. Comparison sorts cannot beat O(n log n) in the worst case (decision-tree lower bound). Radix sort avoids comparisons by exploiting the structure of integers.
2. **LSD (least significant digit first):** sort by the ones digit, then the tens digit, then hundreds, and so on up to the most significant digit of the maximum value.
3. Each per-digit pass must be **stable**: numbers with the same current digit keep the order established by previous (less significant) digits. That is why the final order is correct.
4. Per-digit pass = counting sort on 10 buckets: count digits, prefix-sum the counts to get bucket end positions, place elements iterating **backwards** (that is what makes it stable), copy back.

## Complexity
- Time: O(d * (n + b)), where d = number of digits in the maximum and b = base (10). For fixed-width integers this is O(n).
- Space: O(n + b).

## Interview notes
- Negative numbers: sort negatives and non-negatives separately (negatives by absolute value, reversed), or offset all values.
- Choosing base 256 (bytes) reduces passes for 32-bit integers to 4; this is how high-performance integer sorts work.
- Counting sort alone (single pass over values) is best when the value range is small, e.g. Three Number Sort.
