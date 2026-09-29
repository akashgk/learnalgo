# Subarray Sort

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Find the extremes of the unsorted region

## The problem

Given an array of integers (at least two), return `[start, end]`: the indices of the **smallest** subarray that must be sorted, in place, for the whole array to become sorted ascending. Return `[-1, -1]` if the array is already sorted.

```
[1, 2, 4, 7, 10, 11, 7, 12, 6, 7, 16, 18, 19]  ->  [3, 9]
```

Sorting indices 3..9 (`7, 10, 11, 7, 12, 6, 7`) gives `6, 7, 7, 7, 10, 11, 12`, and the whole array becomes sorted.

## Step 1: Simple baseline

Sort a copy and compare it with the original. The first and last positions where they differ are the answer. **O(n log n) time, O(n) space.** Correct and easy; say it first.

## Step 2: Why the answer is not just "where the first disorder appears"

In the example, the first local violation is `11 > 7` at indices 5 and 6. But the answer starts at index **3**. Why? The value `6` (at index 8) is out of place, and in the sorted array it belongs right after `4`, at index 3. The boundaries of the subarray are determined by **where the misplaced values belong**, not by where the violations are.

## Step 3: The O(n) idea

1. Find every element that is **out of order**: smaller than its left neighbor or larger than its right neighbor.
2. Among them, take the **smallest** value `minBad` and the **largest** value `maxBad`.
3. `minBad` belongs at the first index whose value is **greater** than `minBad`: that is `start`.
4. `maxBad` belongs at the last index whose value is **less** than `maxBad`: that is `end`.

In the example: out-of-order values are 11, 7 (index 6), 12, 6. `minBad = 6`, `maxBad = 12`. The first value greater than 6 is 7 at index 3. The last value less than 12 is 7 at index 9. Answer `[3, 9]`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`subarray_sort.dart`](subarray_sort.dart) (run it with `dart run`).

```dart
// Subarray Sort: smallest [start, end] that, if sorted, sorts the whole array; [-1, -1] if sorted.
// Find the min and max among out-of-order elements, then find their correct positions.
// O(n) time, O(1) space.

List<int> subarraySort(List<int> array) {
  final n = array.length;
  bool outOfOrder(int i) => (i > 0 && array[i] < array[i - 1]) || (i < n - 1 && array[i] > array[i + 1]);

  int? minBad, maxBad;
  for (var i = 0; i < n; i++) {
    if (!outOfOrder(i)) continue;
    if (minBad == null || array[i] < minBad) minBad = array[i];
    if (maxBad == null || array[i] > maxBad) maxBad = array[i];
  }
  if (minBad == null || maxBad == null) return [-1, -1];

  var start = 0;
  while (array[start] <= minBad) {
    start++;
  }
  var end = n - 1;
  while (array[end] >= maxBad) {
    end--;
  }
  return [start, end];
}
```

<!-- CODE:END -->

### Walkthrough

- `outOfOrder(i)` checks both neighbors, guarding the array ends.
- The first loop computes `minBad` and `maxBad`; if both stay null, the array is sorted.
- `while (array[start] <= minBad) start++;` finds the first value greater than `minBad`.
- `while (array[end] >= maxBad) end--;` finds the last value less than `maxBad`.

## Step 5: Dry run

| index | value | out of order? |
|---|---|---|
| 4 | 10 | no (7 < 10 < 11) |
| 5 | 11 | yes (11 > 7 on the right) |
| 6 | 7 | yes (7 < 11 on the left) |
| 7 | 12 | yes (12 > 6 on the right) |
| 8 | 6 | yes (6 < 12 on the left) |
| 9 | 7 | no (6 < 7 < 16) |

`minBad = 6`, `maxBad = 12`. Scanning from the left: 1, 2, 4 are <= 6; index 3 (7) is not: `start = 3`. Scanning from the right: 19, 18, 16 are >= 12; index 9 (7) is not: `end = 9`.

## Complexity

- **Time: O(n)**: three linear scans.
- **Space: O(1)**.

## Alternative compact O(n) formulation

Scan left to right keeping the running maximum; the **last** index where `a[i] < runningMax` is `end`. Scan right to left keeping the running minimum; the last index (smallest i) where `a[i] > runningMin` is `start`. Same result, fewer lines. Know both.

## Common mistakes

- Returning the first and last local violations (misses values that must travel far).
- Using `<` instead of `<=` in the boundary scans (equal values do not need to move).

## Follow-ups

1. **Shortest Unsorted Continuous Subarray (LeetCode #581):** identical, returns the length.
2. **Minimum swaps / moves to sort:** different problems (cycle decomposition of the permutation).

## What to remember

The unsorted window is determined by where the smallest and largest misplaced values belong. Find those two values, then find their correct positions.
