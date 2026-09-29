# Zero Sum Subarray

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Prefix sums + hash set

## The problem

Given an array of integers (positive, negative, or zero), return whether it contains a **non-empty contiguous subarray** whose elements sum to 0.

```
[-5, -5, 2, 3, -2]  ->  true    (-5 + 2 + 3 = 0)
[0]                 ->  true
[1, 2, 3]           ->  false
[4, 2, -1, -1, 3]   ->  true    (2 + -1 + -1 = 0)
```

## Step 1: Work an example by hand

Write the **running total** (prefix sum) under `[4, 2, -1, -1, 3]`:

```
index:        0   1   2   3   4
value:        4   2  -1  -1   3
running sum:  4   6   5   4   7
```

The running sum is 4 after index 0 and **4 again** after index 3. Whatever happened between those points (`2, -1, -1`) must have added up to 0: the total did not change. That is the insight.

## Step 2: Brute force

Check every subarray. With a running sum per start index it is **O(n^2)**:

```dart
for (var i = 0; i < n; i++) {
  var s = 0;
  for (var j = i; j < n; j++) {
    s += nums[j];
    if (s == 0) return true;
  }
}
```

## Step 3: Optimize with prefix sums

Define `P[k]` = sum of the first k elements, with `P[0] = 0` (the empty prefix). The sum of the subarray `nums[i..j]` is `P[j+1] - P[i]`.

So a zero-sum subarray exists **if and only if two prefix sums are equal**.

Now the question is: "while computing prefix sums, have I seen this value before?" That is a hash set lookup: **O(n)** overall.

**Why seed the set with 0?** `P[0] = 0` represents the empty prefix. Without it, a subarray starting at index 0 (like `[0]` or `[3, -3]`) would be missed, because its matching earlier prefix is the empty one.

## Step 4: The code

<!-- CODE:START -->

Full source: [`zero_sum_subarray.dart`](zero_sum_subarray.dart) (run it with `dart run`).

```dart
// Zero Sum Subarray: does any contiguous non-empty subarray sum to 0?
// If two prefix sums are equal, the elements between them sum to 0.
// O(n) time, O(n) space.

bool zeroSumSubarray(List<int> nums) {
  final seenPrefixSums = <int>{0}; // empty prefix, so a prefix that itself sums to 0 counts
  var sum = 0;
  for (final x in nums) {
    sum += x;
    if (!seenPrefixSums.add(sum)) return true; // add returns false if already present
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- `final seenPrefixSums = <int>{0};` seeds the empty prefix.
- `sum += x;` extends the prefix sum.
- `if (!seenPrefixSums.add(sum)) return true;` uses the fact that `Set.add` returns `false` when the value was already present. One call both checks and inserts.

## Step 5: Dry run

`[4, 2, -1, -1, 3]`:

| x | sum | already seen? | set after |
|---|---|---|---|
| (start) | 0 | | {0} |
| 4 | 4 | no | {0, 4} |
| 2 | 6 | no | {0, 4, 6} |
| -1 | 5 | no | {0, 4, 6, 5} |
| -1 | 4 | **yes** | return true |

## Complexity

- **Time: O(n)** (expected, because of hashing).
- **Space: O(n)** for the set.

## Why not a sliding window?

Sliding windows work for "subarray sum" problems only when all numbers are non-negative: then growing the window never decreases the sum, and shrinking never increases it. With negatives, that monotonicity is gone, so you cannot decide which end to move. Prefix sums with a hash map work for any signs. Explaining this is a strong interview signal.

## Common mistakes

- Forgetting to seed the set with 0.
- Checking `sum == 0` only (misses subarrays that do not start at index 0).

## The prefix-sum family (learn these together)

| Problem | Store in the map | Look up |
|---|---|---|
| Any subarray sums to 0 (this problem) | set of prefix sums | current sum |
| Count subarrays with sum k (LeetCode #560) | prefix sum -> count | current sum - k |
| Longest subarray with sum k (hard 06) | prefix sum -> **first** index | current sum - k |
| Subarray sum divisible by k (#974) | `sum % k` -> count | same remainder |
| Contiguous array with equal 0s and 1s (#525) | treat 0 as -1, then "sum 0" | first index |

## What to remember

Subarray sum = difference of two prefix sums. "Is there a subarray with sum X" becomes "have I seen prefix sum `current - X`?", answered with a hash map.
