# Array Of Products

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Prefix and suffix products

## Problem
Given a non-empty integer array, return an array where each index holds the product of every other element. Division is not allowed.

```
[5, 1, 4, 2]  ->  [8, 40, 10, 20]
```

## Building up the logic
1. Brute force: for each i, multiply all j != i. O(n^2).
2. Division trick (total product / array[i]) is banned and also breaks on zeros. Know why: with one zero, only that index is non-zero; with two zeros, everything is zero.
3. Decompose: "everything except i" = (everything left of i) * (everything right of i).
4. Precompute left products and right products in two arrays: O(n) time, O(n) extra space.
5. Space optimization: store left products directly in the output, then sweep right-to-left with a single running suffix product. O(1) extra space besides the output.

## Complexity
- Time: O(n).
- Space: O(n) for the output; O(1) extra.

## Interview notes
- LeetCode #238. The interviewer will almost certainly ask the O(1) extra space follow-up, so go straight to it once you have explained the two-array version.
- Overflow: products grow fast. In Java/C++ mention `long` or that the problem guarantees fit.
