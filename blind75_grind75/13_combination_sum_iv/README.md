# Combination Sum IV

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Counting ordered sequences (loop order matters) | **Source:** LeetCode 377; Blind 75 (the original list's "Combination Sum")

## The problem

Given distinct positive integers `nums` and a `target`, count the **ordered** sequences of numbers from `nums` (reuse allowed) that sum to `target`. Despite the name, order matters: `(1, 2)` and `(2, 1)` are different.

```
nums = [1, 2, 3], target = 4  ->  7
1+1+1+1, 1+1+2, 1+2+1, 2+1+1, 2+2, 1+3, 3+1
```

## Step 1: Think about the last number

Every sequence summing to `t` ends with some number `x` from `nums`. Remove it, and what remains is a sequence summing to `t - x`. So:

```
ways[t] = sum over x in nums (x <= t) of ways[t - x]
ways[0] = 1   (the empty sequence)
```

Exactly the Climbing Stairs recurrence (steps of size `x` for every `x` in `nums`).

## Step 2: Loop order: sequences vs. sets

Compare with Coin Change II (AlgoExpert medium 29 Number Of Ways To Make Change), which counts **combinations** (order does not matter):

| Problem | Outer loop | Inner loop | Counts |
|---|---|---|---|
| Coin Change II | coins | totals | multisets: each coin's uses are added in a fixed order, so `1+2` and `2+1` are the same |
| Combination Sum IV | totals | numbers | sequences: for each total, any number can be last |

Swapping the loops switches between the two problems. Knowing **why** is a classic interview check.

## Step 3: The code

<!-- CODE:START -->

Full source: [`combination_sum_iv.dart`](combination_sum_iv.dart) (run it with `dart run`).

```dart
// Combination Sum IV: distinct positive nums; count ordered sequences (order matters, reuse allowed)
// that sum to target. dp[t] = sum over x of dp[t - x], with dp[0] = 1: the last number of the
// sequence is any x. O(target * n) time, O(target) space.

int combinationSum4(List<int> nums, int target) {
  final dp = List<int>.filled(target + 1, 0);
  dp[0] = 1; // the empty sequence
  // Totals on the OUTSIDE: every order of the same numbers is counted (sequences, not sets).
  for (var t = 1; t <= target; t++) {
    for (final x in nums) {
      if (x <= t) dp[t] += dp[t - x];
    }
  }
  return dp[target];
}
```

<!-- CODE:END -->

### Walkthrough

- `dp[0] = 1`: one way to make 0.
- For each total `t`, every number `x <= t` can be the last element.

## Step 4: Dry run

`[1, 2, 3]`, target 4:

| t | dp[t - 1] | dp[t - 2] | dp[t - 3] | dp[t] |
|---|---|---|---|---|
| 0 | | | | 1 |
| 1 | 1 | | | 1 |
| 2 | 1 | 1 | | 2 |
| 3 | 2 | 1 | 1 | 4 |
| 4 | 4 | 2 | 1 | **7** |

## Complexity

- Time: **O(target * n)**.
- Space: **O(target)**.

## Edge cases

- No number fits: 0.
- A single number 1: exactly one sequence.
- Large counts: LeetCode guarantees the answer fits in 32 bits, but intermediate `dp` values can be larger in some inputs; Dart ints are 64-bit.

## Common mistakes

- Using the Coin Change II loop order (counts combinations, not sequences).
- Starting `dp[0]` at 0.

## Follow-ups you should be ready for

1. **Negative numbers allowed.** Then sequences can be infinitely long (`1 + (-1) + 1 + ...`): you must cap the length.
2. **Combination Sum (LeetCode 39), II (LeetCode 40).** List the combinations: backtracking; more_problems 24 and neetcode 25.
3. **Climbing Stairs.** This with `nums = [1, 2]`.

## What to remember

Counting ordered sequences: totals outside, choices inside. Counting unordered combinations: choices outside, totals inside.
