# Max Subset Sum No Adjacent

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Linear DP (take or skip)

## The problem

Given an array of positive integers, return the maximum sum of a subset of its elements such that **no two chosen elements are adjacent** in the array. An empty array gives 0.

```
[75, 105, 120, 75, 90, 135]  ->  330   (75 + 120 + 135)
[7, 10, 12, 7, 9, 14]        ->  33    (7 + 12 + 14)
```

This is the famous "House Robber" problem: houses in a row, adjacent houses have linked alarms, maximize the loot.

## Step 1: Work an example by hand

Greedy ideas fail. "Take the biggest element first": in `[75, 105, 120, 75, 90, 135]`, taking 135 then 120 then 75 gives 330 here, but on `[2, 3, 2]` taking the biggest (3) gives 3 while `2 + 2 = 4` is better. "Take every other element": `75 + 120 + 90 = 285` or `105 + 75 + 135 = 315`, both worse than 330.

We need to consider choices systematically, which suggests dynamic programming.

## Step 2: Brute force

Each element is either taken or skipped, with the rule that taking one forbids its neighbor. Recursively:

```
best(i) = max( best(i + 1),              # skip element i
               a[i] + best(i + 2) )      # take element i, skip i + 1
```

Without caching this explores about 1.6^n branches (a Fibonacci-shaped call tree).

## Step 3: Define the DP

**Subproblem:** `B[i]` = the best sum using only elements `0..i`.

**Recurrence:** look at the last element `a[i]`:

- skip it: the best is `B[i-1]`;
- take it: then `a[i-1]` is forbidden, so the best is `B[i-2] + a[i]`.

```
B[i] = max(B[i-1], B[i-2] + a[i])
B[0] = a[0]
B[1] = max(a[0], a[1])
```

The answer is `B[n-1]`.

**Space optimization:** `B[i]` needs only the previous two values. Keep two variables, like Fibonacci.

## Step 4: The code

<!-- CODE:START -->

Full source: [`max_subset_sum_no_adjacent.dart`](max_subset_sum_no_adjacent.dart) (run it with `dart run`).

```dart
// Max Subset Sum No Adjacent (House Robber). best(i) = max(best(i-1), best(i-2) + a[i]).
// O(n) time, O(1) space.

int maxSubsetSumNoAdjacent(List<int> array) {
  var prev2 = 0, prev1 = 0; // best sums ending before i-1 and before i
  for (final x in array) {
    final current = prev1 > prev2 + x ? prev1 : prev2 + x;
    prev2 = prev1;
    prev1 = current;
  }
  return prev1;
}
```

<!-- CODE:END -->

### Walkthrough

- `prev1` is `B[i-1]` (best up to the previous element), `prev2` is `B[i-2]`.
- Starting both at 0 means "before the array, the best sum is 0", which makes the base cases fall out automatically: for the first element, `max(0, 0 + a[0]) = a[0]`; for the second, `max(a[0], 0 + a[1])`.
- `current = max(prev1, prev2 + x)` is the recurrence.
- Shift: `prev2 = prev1; prev1 = current;`.

## Step 5: Dry run

`[75, 105, 120, 75, 90, 135]`:

| x | prev2 | prev1 | current = max(prev1, prev2 + x) |
|---|---|---|---|
| 75 | 0 | 0 | 75 |
| 105 | 0 | 75 | 105 |
| 120 | 75 | 105 | 195 |
| 75 | 105 | 195 | 195 |
| 90 | 195 | 195 | 285 |
| 135 | 195 | 285 | **330** |

## Complexity

- **Time: O(n)**.
- **Space: O(1)** (O(n) with the full table, needed only if you must reconstruct which elements were chosen).

## Common mistakes

- Greedy selection.
- Wrong base case for index 1 (`B[1] = a[1]` instead of `max(a[0], a[1])`).
- Assuming values are positive in variants where they can be negative (then "take nothing" must be allowed explicitly).

## Follow-ups

1. **House Robber II (LeetCode #213):** houses in a circle, so the first and last are adjacent. Run the linear version twice: once without the first house, once without the last, take the max.
2. **House Robber III (#337):** houses on a binary tree. Each subtree returns a pair `(bestIfRobbed, bestIfNotRobbed)`; bottom-up DP on the tree.
3. **Delete and Earn (#740):** reduces to this problem after bucketing values.
4. **Reconstruct the chosen elements:** keep the full table and walk back: if `B[i] == B[i-1]`, element i was skipped; otherwise it was taken and you jump to `i - 2`.

## How to recognize it

"Choose elements from a sequence, each choice forbids its neighbors, maximize the sum": take/skip linear DP.

## What to remember

Define `B[i]` as the best answer using a prefix. Decide on the last element (take or skip). Keep only the states the recurrence needs.
