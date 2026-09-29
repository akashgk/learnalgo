# Partition Equal Subset Sum

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** 0/1 knapsack reachability (subset sum) | **Source:** LeetCode 416; Striver A2Z, NeetCode 150

## The problem

Given positive integers, can they be split into two subsets with **equal sums**?

```
[1, 5, 11, 5]  ->  true     ([1, 5, 5] and [11])
[1, 2, 3, 5]   ->  false    (total 11 is odd)
[1, 2, 5]      ->  false    (total 8, but no subset sums to 4)
```

## Step 1: Reduce to subset sum

If the total `S` is odd, the answer is false. Otherwise the two halves each sum to `S / 2`, and choosing one half determines the other. So the question is:

**Is there a subset summing to exactly `S / 2`?**

That is the classic subset sum problem, a 0/1 knapsack where each item is either taken or not.

## Step 2: Brute force

Each element is in the subset or not: 2^n subsets. Recursion `canMake(i, target) = canMake(i + 1, target) || canMake(i + 1, target - nums[i])`. Exponential.

## Step 3: Overlapping subproblems

The recursion depends only on `(i, target)`, and many different choice sequences lead to the same pair. There are only `n * (S/2 + 1)` distinct pairs: memoize, or build a table.

`dp[i][s]` = "some subset of the first `i` numbers sums to `s`":

```
dp[0][0] = true, dp[0][s > 0] = false
dp[i][s] = dp[i-1][s]                       (skip nums[i-1])
        || dp[i-1][s - nums[i-1]]            (take it, if s >= nums[i-1])
```

## Step 4: One row, iterated backwards

Row `i` only reads row `i - 1`. Keep a single boolean array `reachable[s]` and update it in place for each number `x`, looping `s` **from high to low**:

```
for s from target down to x:
  if reachable[s - x]: reachable[s] = true
```

**Why backwards?** Going forwards, `reachable[s - x]` might already have been set **in this same round** using `x`, so `x` would be counted twice (that is the **unbounded** knapsack, where reuse is allowed). Going backwards, every `reachable[s - x]` we read still describes subsets **without** `x`.

## Step 5: The code

<!-- CODE:START -->

Full source: [`partition_equal_subset_sum.dart`](partition_equal_subset_sum.dart) (run it with `dart run`).

```dart
// Partition Equal Subset Sum: can the array (positive integers) be split into two subsets
// with equal sums? Equivalent to: is there a subset summing to total / 2?
// 0/1 knapsack reachability with a 1-D table iterated backwards. O(n * S) time, O(S) space.

bool canPartition(List<int> nums) {
  final total = nums.fold(0, (a, b) => a + b);
  if (total.isOdd) return false;
  final target = total ~/ 2;
  final reachable = List<bool>.filled(target + 1, false);
  reachable[0] = true; // the empty subset
  for (final x in nums) {
    // Backwards, so reachable[s - x] still describes subsets WITHOUT x (each item used once).
    for (var s = target; s >= x; s--) {
      if (reachable[s - x]) reachable[s] = true;
    }
    if (reachable[target]) return true;
  }
  return reachable[target];
}
```

<!-- CODE:END -->

### Walkthrough

- Odd totals exit immediately.
- `reachable[0] = true`: the empty subset.
- The early `return true` once `reachable[target]` is set saves work.

## Step 6: Dry run

`[1, 5, 11, 5]`, total 22, target 11. Sums reachable after each number:

| number | reachable sums |
|---|---|
| (start) | 0 |
| 1 | 0, 1 |
| 5 | 0, 1, 5, 6 |
| 11 | 0, 1, 5, 6, **11** (0 + 11) -> return true |

## Complexity

- Time: **O(n * S)**, S = total sum. This is **pseudo-polynomial**: polynomial in the numeric value of the sum, not in the input size. Subset sum is NP-complete in general.
- Space: **O(S)**.

## Edge cases

- One element: false (the other subset would be empty with sum 0, and the element is positive).
- Two equal elements: true.
- Large values with small n: the table is large; a bitset (`bits |= bits << x`) makes it about 64 times faster in languages with big bitsets.

## Common mistakes

- Iterating `s` forwards (reusing a number).
- Forgetting the odd-total check (then `S / 2` is rounded and the answer can be wrong).
- Using a greedy (take the largest number that still fits under S / 2): fails on `[3, 3, 2, 2, 2, 2]`. The target is 7; greedy takes 3 + 3 = 6 and then no 2 fits, but `3 + 2 + 2 = 7` exists.

## Follow-ups you should be ready for

1. **Count subsets with sum k (Striver).** Replace `||` with `+`.
2. **Partition into two subsets with minimum difference (Striver).** Find all reachable sums up to `S / 2`; the answer is `S - 2 * (largest reachable)`.
3. **Target Sum (LeetCode 494).** Assign + or - to each number: it becomes "count subsets with sum `(S + target) / 2`".
4. **Partition into k equal subsets (LeetCode 698).** Backtracking with bitmask memoization; the DP above does not generalize directly.

## What to remember

"Split into two equal halves" = "subset sum to S / 2" = 0/1 knapsack. One boolean row, iterated backwards so each item is used at most once.
