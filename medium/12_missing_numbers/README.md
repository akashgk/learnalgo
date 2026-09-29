# Missing Numbers

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Math / XOR partitioning

## Problem
You are given an unsorted array of distinct integers taken from `1..n`, where `n = length + 2`. Exactly two numbers are missing. Return them sorted ascending.

```
[1, 4, 3]  ->  [2, 5]      (n = 5)
```

## Building up the logic
1. **Hash set:** put everything in a set, scan 1..n. O(n) time, O(n) space. Correct, but the interviewer will ask for O(1) space.
2. **One missing number** (warm-up): expected sum minus actual sum. Or XOR 1..n with the array; pairs cancel and the missing value remains.
3. **Two missing numbers, sum approach:** total missing `S = a + b`. Since `a != b`, one is below `S / 2` and the other above. Sum only values `<= S ~/ 2` in both the range and the array: the difference is the smaller missing number. The other is `S - a`.
4. **Two missing numbers, XOR approach (used here):** XOR of 1..n and the array leaves `a ^ b`. Any set bit in `a ^ b` is a bit where `a` and `b` differ. Partition every number (range and array) by that bit and XOR each group separately; each group isolates exactly one missing number.
5. `x & -x` extracts the lowest set bit (two's complement trick). Learn it.

## Complexity
| Approach | Time | Space |
|---|---|---|
| Hash set | O(n) | O(n) |
| Sum split / XOR split | O(n) | O(1) |

## Interview notes
- The XOR partition trick also solves "every number appears twice except two" (LeetCode #260).
- Sum-based versions risk overflow for huge n in fixed-width languages; XOR never overflows.
