# Three Number Sum

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort + two pointers

## Problem
Given an array of distinct integers and a target sum, return every triplet that sums to the target. Each triplet is sorted ascending and the list of triplets is sorted ascending too.

```
[12, 3, 1, 2, -6, 5, -8, 6], target 0  ->  [[-8, 2, 6], [-8, 3, 5], [-6, 1, 5]]
```

## Building up the logic
1. Brute force: three nested loops, O(n^3).
2. Reduce to a known problem: fix the first number `a[i]`; now you need two numbers in the rest summing to `target - a[i]`. That is Two Number Sum.
3. Which Two Number Sum? The sorted two-pointer version: it needs no extra memory and, because the array is sorted, it naturally produces triplets in sorted order.
4. After a match, move **both** pointers. Moving only one cannot produce another match with distinct values (the partner would have to equal the value you just used).
5. Pointer movement proof: if the sum is too small, `a[lo]` paired with anything at or left of `hi` is also too small, so `a[lo]` is useless; discard it. Symmetric for too large.

## Complexity
- Time: O(n^2): sorting is O(n log n), then n iterations of an O(n) two-pointer scan.
- Space: O(n) for the sorted copy (O(1) extra if sorting in place), plus the output.

## Edge cases
- Fewer than three elements: loop does not run.
- With duplicates allowed (LeetCode #15), skip equal values for `i`, and after a match skip equal values for `lo`/`hi`, to avoid duplicate triplets.

## Interview notes
- Why not a hash set per `i` (also O(n^2))? It works but uses O(n) extra memory and complicates ordering and deduplication. Two pointers is the expected answer.
- The general k-sum reduces to (k-2) nested loops + two pointers: O(n^(k-1)).
