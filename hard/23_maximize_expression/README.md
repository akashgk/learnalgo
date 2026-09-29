# Maximize Expression

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Chained running maxima

## Problem
Given an integer array, return the maximum value of `array[a] - array[b] + array[c] - array[d]` over indices `a < b < c < d`. If the array has fewer than 4 elements, return 0.

```
[3, 6, 1, -3, 2, 7]  ->  4   (6 - (-3) + 2 - 7)
```

## Building up the logic
1. Brute force: four nested loops, O(n^4).
2. Build the expression one term at a time, left to right. Define running maxima over prefixes:
   - `A[i]` = max `array[a]` for `a <= i`
   - `AB[i]` = max `A[b-1] - array[b]` for `b <= i`
   - `ABC[i]` = max `AB[c-1] + array[c]` for `c <= i`
   - `ABCD[i]` = max `ABC[d-1] - array[d]` for `d <= i`
3. Each stage uses the previous stage at index `i - 1`, which enforces the strict index order.
4. Answer: `ABCD[n-1]`.
5. Each array only reads its own previous value and the previous stage, so four scalar variables suffice if you update them in reverse stage order per element. The array version is easier to explain first.

## Complexity
- Time: O(n).
- Space: O(n) (O(1) with rolling variables).

## Interview notes
- This "state machine of partial expressions" is the same idea as Best Time to Buy and Sell Stock III (at most two transactions, LeetCode #123). There, `buy1`, `sell1`, `buy2`, `sell2` track the best `-p1`, `-p1 + p2`, `-p1 + p2 - p3`, `-p1 + p2 - p3 + p4` over increasing days; here the stages track `a`, `a - b`, `a - b + c`, `a - b + c - d` the same way.
