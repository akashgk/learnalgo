# Longest Subarray With Sum

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Sliding window (non-negative values) / prefix-sum map (any values)

## The problem

Given an array of **non-negative** integers and a target sum, return `[start, end]` (inclusive) of the **longest** contiguous subarray whose sum equals the target, or `[]` if none exists.

```
[1, 2, 15, 3, 4, 5, 6, 7, 8], target 30  ->  [0, 5]    (1 + 2 + 15 + 3 + 4 + 5)
                                              ([4, 8] = 4+5+6+7+8 also sums to 30 but is shorter)
[0, 0, 5, 0, 0], target 5                ->  [0, 4]
```

## Step 1: Brute force

For each start, extend the end with a running sum and record matches: **O(n^2)**.

## Step 2: Sliding window, and why it needs non-negative values

With non-negative values:

- extending the window to the right can only **increase or keep** the sum;
- shrinking it from the left can only **decrease or keep** the sum.

So for each right end, the valid left ends form a contiguous range, and as the right end moves right, the left boundary never needs to move back. That monotonicity is what makes the sliding window correct.

Algorithm:

```
left = 0, sum = 0
for right in 0..n-1:
    sum += a[right]
    while sum > target and left < right: sum -= a[left]; left++
    if sum == target: record [left, right] if longer
```

Each index enters and leaves the window once: O(n).

**Zeros** are why this problem asks for the **longest**: `[0, 0, 5, 0, 0]` with target 5 is the whole array. The window keeps leading zeros because it only shrinks when the sum is too big, and it extends over trailing zeros because they keep the sum at 5.

## Step 3: What if values can be negative?

The monotonicity breaks: shrinking could increase the sum. Use **prefix sums** (as in Zero Sum Subarray): the subarray `(i, j]` sums to target iff `P[j] - P[i] = target`. Store the **first** index where each prefix sum occurs (first, because an earlier start means a longer subarray) and look up `P[j] - target`. O(n) time, O(n) space. This file includes that version too.

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_subarray_with_sum.dart`](longest_subarray_with_sum.dart) (run it with `dart run`).

```dart
// Longest Subarray With Sum (non-negative integers): sliding window.
// Returns [start, end] of the longest subarray summing to target, or [] if none.
// O(n) time, O(1) space. (For arrays with negatives, see the prefix-sum map below.)

List<int> longestSubarrayWithSum(List<int> array, int targetSum) {
  var best = <int>[];
  var sum = 0, left = 0;
  for (var right = 0; right < array.length; right++) {
    sum += array[right];
    while (sum > targetSum && left < right) {
      sum -= array[left++];
    }
    if (sum == targetSum && (best.isEmpty || right - left > best[1] - best[0])) {
      best = [left, right];
    }
  }
  return best;
}

/// Works with negative numbers: first index of each prefix sum. O(n) time, O(n) space.
List<int> longestSubarrayWithSumAnySign(List<int> array, int targetSum) {
  final firstIndex = <int, int>{0: -1};
  var best = <int>[], sum = 0;
  for (var i = 0; i < array.length; i++) {
    sum += array[i];
    final start = firstIndex[sum - targetSum];
    if (start != null && (best.isEmpty || i - (start + 1) > best[1] - best[0])) {
      best = [start + 1, i];
    }
    firstIndex.putIfAbsent(sum, () => i); // keep the earliest index for the longest span
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough of the sliding window

- `sum` is the window's sum; `left` its left end.
- The inner `while` shrinks while too big. `left < right` keeps the window non-empty.
- A match is recorded only if it is longer than the best so far.

### Walkthrough of the prefix-sum version

- `firstIndex = {0: -1}`: the empty prefix ends "before index 0".
- For each `i`, look up the prefix sum `sum - target`; if it first occurred at `start`, the subarray `start + 1 .. i` sums to target.
- `putIfAbsent` keeps only the earliest index for each prefix sum.

## Step 5: Dry run (sliding window, target 30)

| right | value | sum after add | shrink | window | match |
|---|---|---|---|---|---|
| 0 | 1 | 1 | | [0,0] | |
| 1 | 2 | 3 | | [0,1] | |
| 2 | 15 | 18 | | [0,2] | |
| 3 | 3 | 21 | | [0,3] | |
| 4 | 4 | 25 | | [0,4] | |
| 5 | 5 | 30 | | [0,5] | **[0, 5]** (length 6) |
| 6 | 6 | 36 | drop 1, 2, 15: sum 18 | [3,6] | |
| 7 | 7 | 25 | | [3,7] | |
| 8 | 8 | 33 | drop 3: sum 30 | [4,8] | length 5, shorter |

## Complexity

| Approach | Time | Space | Works with negatives? |
|---|---|---|---|
| Brute force | O(n^2) | O(1) | yes |
| Sliding window | O(n) | O(1) | **no** |
| Prefix-sum map | O(n) | O(n) | yes |

## Common mistakes

- Using a sliding window when negatives are possible.
- Storing the **latest** index of each prefix sum (gives shorter subarrays).

## Follow-ups

1. **Maximum Size Subarray Sum Equals k (LeetCode #325):** the prefix-sum version.
2. **Subarray Sum Equals K (#560):** count subarrays; store counts of prefix sums.
3. **Minimum Size Subarray Sum (#209):** shortest subarray with sum >= target; sliding window (positive values).

## What to remember

Sliding windows need a monotonic window property (non-negative values). Without it, fall back to prefix sums with a hash map.
