# Missing Number

**Difficulty:** Easy | **Category:** Bit Manipulation | **Pattern:** XOR indices with values (or the sum formula) | **Source:** LeetCode 268; NeetCode 150, Blind 75

## The problem

An array contains `n` distinct numbers taken from `0..n` (n + 1 possible values), so exactly one is missing. Find it in O(n) time and O(1) space.

```
[3, 0, 1]  ->  2
[0, 1]     ->  2     (the missing number can be n itself)
```

AlgoExpert medium 12 Missing Numbers is the version with **two** missing values.

## Step 1: Sum formula

The numbers `0..n` add up to `n(n + 1) / 2`. Subtract the actual sum: the difference is the missing number. O(n), O(1). In fixed-width languages the sum can overflow for large n (Dart ints are 64-bit, so not here).

## Step 2: XOR, which cannot overflow

XOR every index `0..n-1`, the value `n`, and every array value. Each number that is present appears twice (once as an index or `n`, once as a value) and cancels; the missing number appears only once (as an index or `n`), so it remains. Same reasoning as Single Number (neetcode 54).

## Step 3: The code

<!-- CODE:START -->

Full source: [`missing_number.dart`](missing_number.dart) (run it with `dart run`).

```dart
// Missing Number: n distinct numbers from 0..n, exactly one missing. Find it in O(n) time, O(1) space.
// XOR every index 0..n with every value: each present number cancels with its index, leaving the
// missing one. (The sum formula n(n+1)/2 - sum also works; XOR cannot overflow.)

int missingNumber(List<int> nums) {
  var x = nums.length; // index n has no slot in the loop, so start with it
  for (var i = 0; i < nums.length; i++) {
    x ^= i ^ nums[i];
  }
  return x;
}
```

<!-- CODE:END -->

### Walkthrough

- `x` starts at `n` because the loop only covers indices `0..n-1`.
- `x ^= i ^ nums[i]` folds in both the index and the value.

## Step 4: Dry run

`[3, 0, 1]`, n = 3:

| i | nums[i] | x after |
|---|---|---|
| start | | 3 |
| 0 | 3 | 3 ^ 0 ^ 3 = 0 |
| 1 | 0 | 0 ^ 1 ^ 0 = 1 |
| 2 | 1 | 1 ^ 2 ^ 1 = **2** |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Missing 0: `[1]` -> 0.
- Missing n: `[0, 1]` -> 2.

## Common mistakes

- Forgetting to include `n` (fails when n is the missing value).
- Sorting (O(n log n)) or a hash set (O(n) space) when O(1) was asked.

## Follow-ups you should be ready for

1. **Two missing numbers.** XOR gives `a ^ b`; split by a differing bit (more_problems 49), or use the sum and the sum of squares.
2. **Missing and repeating.** Similar XOR partitioning.
3. **First Missing Positive (LeetCode 41).** Values are arbitrary: in-place cyclic placement.

## What to remember

Pair every index with every value: XOR cancels the pairs and leaves the missing number. Remember to include n.
