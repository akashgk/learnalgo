# Binary Subarrays With Sum

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** exactly(k) = atMost(k) - atMost(k - 1), sliding window | **Source:** LeetCode 930; Striver A2Z

## The problem

Given an array of 0s and 1s and an integer `goal`, count the non-empty subarrays whose sum is exactly `goal`.

```
[1, 0, 1, 0, 1], goal = 2   ->  4
[0, 0, 0, 0, 0], goal = 0   ->  15
```

## Step 1: Why a plain window cannot count "exactly"

A sliding window finds, for each `right`, a single `left` boundary. But with zeros, **many** left boundaries give the same sum. In `[0, 1, 0, 1]` with goal 2, ending at the last 1, both `[0, 1, 0, 1]` and `[1, 0, 1]` have sum 2. Leading zeros can be added or removed freely, so the set of valid lefts is a **range**, and a single-pointer window does not directly count it.

## Step 2: Option A, prefix sums (works for any integers)

This is more_problems 06 Subarray Sum Equals K: a map of prefix-sum counts. O(n) time, O(n) space. It is a perfectly good answer here.

## Step 3: Option B, the atMost trick (O(1) space)

"At most" **is** easy with a window. Because all values are non-negative, extending a window never decreases its sum. For each `right`, shrink `left` until `sum <= goal`. Then **every** start in `[left, right]` gives a subarray with sum `<= goal` (starting later only removes non-negative values). That is `right - left + 1` subarrays ending at `right`.

Then:

```
exactly(goal) = atMost(goal) - atMost(goal - 1)
```

Subarrays with sum `<= goal`, minus those with sum `<= goal - 1`, leaves those with sum exactly `goal`. `atMost(-1)` is 0.

This trick is worth memorizing: it turns every "count subarrays with **exactly** K of something" (K odd numbers, K distinct integers) into two easy window passes.

## Step 4: The code

<!-- CODE:START -->

Full source: [`binary_subarrays_with_sum.dart`](binary_subarrays_with_sum.dart) (run it with `dart run`).

```dart
// Binary Subarrays With Sum: count subarrays of a 0/1 array with sum exactly goal.
// "exactly(goal) = atMost(goal) - atMost(goal - 1)", each counted with a sliding window.
// O(n) time, O(1) space. (The prefix-sum hash map also works, with O(n) space.)

int numSubarraysWithSum(List<int> nums, int goal) => _atMost(nums, goal) - _atMost(nums, goal - 1);

/// Number of subarrays whose sum is <= [goal]. Valid because all values are non-negative,
/// so extending a window never decreases its sum.
int _atMost(List<int> nums, int goal) {
  if (goal < 0) return 0;
  var left = 0, sum = 0, count = 0;
  for (var right = 0; right < nums.length; right++) {
    sum += nums[right];
    while (sum > goal) {
      sum -= nums[left++];
    }
    // Every subarray ending at right and starting in [left, right] is valid.
    count += right - left + 1;
  }
  return count;
}
```

<!-- CODE:END -->

### Walkthrough

- `_atMost` returns 0 for a negative goal: no subarray has a negative sum.
- `while (sum > goal)` shrinks from the left.
- `count += right - left + 1` counts all valid starts for this `right` at once.

## Step 5: Dry run

`[1, 0, 1, 0, 1]`, goal = 2.

atMost(2):

| right | sum after shrinking | left | added | total |
|---|---|---|---|---|
| 0 | 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 2 | 3 |
| 2 | 2 | 0 | 3 | 6 |
| 3 | 2 | 0 | 4 | 10 |
| 4 | 2 | 1 | 4 | 14 |

atMost(1):

| right | sum after shrinking | left | added | total |
|---|---|---|---|---|
| 0 | 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 2 | 3 |
| 2 | 1 | 1 | 2 | 5 |
| 3 | 1 | 1 | 3 | 8 |
| 4 | 1 | 3 | 2 | 10 |

Answer: 14 - 10 = **4**.

## Complexity

- Time: **O(n)** (two passes, each pointer moves at most n times).
- Space: **O(1)**.

## Edge cases

- All zeros with goal 0: `n(n+1)/2`.
- `goal` larger than the number of ones: 0 (both atMost values are the total count of subarrays).

## Common mistakes

- Trying to count "exactly" with one window.
- Forgetting the `goal < 0` guard (the window would shrink past `right`).
- Using this trick with negative numbers: atMost breaks because sums are no longer monotone as the window grows.

## Follow-ups you should be ready for

1. **Count Number of Nice Subarrays (LeetCode 1248).** Exactly k odd numbers: map each value to `x % 2` and reuse this code.
2. **Subarrays with K Different Integers (LeetCode 992).** exactly(K) = atMost(K) - atMost(K - 1) with a frequency map.
3. **Why does option A also work?** It does not rely on non-negativity; it is the general tool.

## What to remember

Counting subarrays with **exactly** k is hard with a window; counting **at most** k is easy. Subtract two at-most counts.
