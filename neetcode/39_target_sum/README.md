# Target Sum

**Difficulty:** Medium | **Category:** 2-D Dynamic Programming | **Pattern:** Reduce to subset-sum counting | **Source:** LeetCode 494; NeetCode 150

## The problem

Put `+` or `-` in front of every number. Count the assignments whose total equals `target`.

```
[1, 1, 1, 1, 1], target 3  ->  5   (choose which one of the five gets '-')
```

## Step 1: Brute force

Two choices per number: 2^n assignments. A DP over `(index, running sum)` works too, with sums ranging over `[-S, S]`: O(n * S).

## Step 2: The algebra trick

Split the numbers into `P` (plus) and `N` (minus). Then:

```
sum(P) - sum(N) = target
sum(P) + sum(N) = S          (every number is in exactly one group)
=> 2 * sum(P) = S + target
=> sum(P) = (S + target) / 2
```

So the question becomes: **how many subsets have sum `(S + target) / 2`?** If `S + target` is odd, or `|target| > S`, the answer is 0.

That is 0/1 knapsack **counting**: `ways[s]` = number of subsets with sum `s`. For each number `x`, update `s` from high to low: `ways[s] += ways[s - x]`. Backwards iteration keeps each number used at most once (same reason as more_problems 39).

## Step 3: Zeros

A 0 can be `+0` or `-0`: two different assignments with the same sum. The update `ways[s] += ways[s - 0]` doubles every count, which is exactly right. (With the loop `s >= x`, `x = 0` visits every `s` down to 0.)

## Step 4: The code

<!-- CODE:START -->

Full source: [`target_sum.dart`](target_sum.dart) (run it with `dart run`).

```dart
// Target Sum: put '+' or '-' before every number; count the assignments whose total is target.
// Let P be the numbers with '+'. Then sum(P) - (S - sum(P)) = target, so sum(P) = (S + target) / 2.
// Count subsets with that sum: 0/1 knapsack counting, iterated backwards. O(n * S) time, O(S) space.

int findTargetSumWays(List<int> nums, int target) {
  final total = nums.fold(0, (a, b) => a + b);
  if (target.abs() > total || (total + target).isOdd) return 0;
  final want = (total + target) ~/ 2;
  final ways = List<int>.filled(want + 1, 0);
  ways[0] = 1; // the empty subset
  for (final x in nums) {
    // Backwards so each number is used at most once. A 0 doubles every count (+0 and -0 differ).
    for (var s = want; s >= x; s--) {
      ways[s] += ways[s - x];
    }
  }
  return ways[want];
}
```

<!-- CODE:END -->

### Walkthrough

- The early exit covers impossible targets and odd `S + target`.
- `ways[0] = 1`: the empty subset.
- Backwards inner loop.

## Step 5: Dry run

`[1, 1, 1, 1, 1]`, target 3: S = 5, want = 4. `ways[0..4]` after each number:

| after number | ways |
|---|---|
| start | 1 0 0 0 0 |
| 1st | 1 1 0 0 0 |
| 2nd | 1 2 1 0 0 |
| 3rd | 1 3 3 1 0 |
| 4th | 1 4 6 4 1 |
| 5th | 1 5 10 10 **5** |

(The rows are binomial coefficients: choosing which ones are `+`.)

## Complexity

- Time: **O(n * S)**.
- Space: **O(S)**.

## Edge cases

- Target larger than the total: 0.
- Negative target: the formula works (`(S + target) / 2` is still the plus-sum); the `abs` check handles out-of-range values.
- Zeros: doubling, as explained.

## Common mistakes

- Forgetting the parity check (integer division silently rounds).
- Iterating forwards (counts reuse).
- Mishandling zeros by skipping them.

## Follow-ups you should be ready for

1. **Partition Equal Subset Sum.** The boolean version with target `S / 2`; more_problems 39.
2. **Last Stone Weight II.** Minimize `|sum(P) - sum(N)|`: find the reachable subset sum closest to `S / 2`.
3. **Memoized recursion over (index, sum).** A valid answer without the algebra; mention the O(n * S) bound.

## What to remember

"Assign + or - to hit a target" is "choose the plus-set with sum (S + target) / 2": a subset-sum count.
