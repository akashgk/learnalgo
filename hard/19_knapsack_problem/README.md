# Knapsack Problem

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** 0/1 knapsack

## The problem

You have items, each given as `[value, weight]`, and a knapsack with a weight capacity. Choose a subset of items (each at most once) whose total weight fits, maximizing the total value. Return `[maxValue, [indices of chosen items]]`.

```
items = [[1, 2], [4, 3], [5, 6], [6, 7]], capacity = 10
->  [10, [1, 3]]      (value 4 + 6, weight 3 + 7 = 10)
```

## Step 1: Why greedy fails

"Take items by best value/weight ratio" is optimal only for the **fractional** knapsack (where you may take part of an item). For 0/1 knapsack, a counterexample:

- capacity 10, items A = (value 7, weight 6), B = (5, 5), C = (5, 5).
- Ratios: A 1.17, B 1.0, C 1.0. Greedy takes A, then nothing else fits: **7**.
- Optimal: B + C = **10**.

## Step 2: Brute force

Try all 2^n subsets: exponential.

## Step 3: The DP

Consider items one at a time. For item `i` (value `v`, weight `w`), there are two choices: skip it or take it.

`best[i][c]` = the best value using only the first `i` items with capacity `c`.

```
best[0][c] = 0
best[i][c] = best[i-1][c]                                  (skip item i)
best[i][c] = max(best[i][c], best[i-1][c - w] + v)          (take it, if w <= c)
```

Answer: `best[n][capacity]`.

### The table for the example

Rows are "items considered so far", columns are capacities 0..10:

```
cap:          0  1  2  3  4  5  6  7  8  9  10
no items      0  0  0  0  0  0  0  0  0  0  0
+ [1, 2]      0  0  1  1  1  1  1  1  1  1  1
+ [4, 3]      0  0  1  4  4  5  5  5  5  5  5
+ [5, 6]      0  0  1  4  4  5  5  5  6  9  9
+ [6, 7]      0  0  1  4  4  5  5  6  6  9  10
```

## Step 4: Reconstruct the chosen items

Walk back from `best[n][capacity]`. If `best[i][c] != best[i-1][c]`, item `i - 1` (0-based) was taken: record it and subtract its weight from `c`. Otherwise it was skipped.

## Step 5: The code

<!-- CODE:START -->

Full source: [`knapsack_problem.dart`](knapsack_problem.dart) (run it with `dart run`).

```dart
// 0/1 Knapsack: items [value, weight], capacity. Returns [maxValue, [item indices]].
// DP table best[i][c] over first i items and capacity c, then backtrack.
// O(n * c) time and space.

List<Object> knapsackProblem(List<List<int>> items, int capacity) {
  final n = items.length;
  final best = List.generate(n + 1, (_) => List<int>.filled(capacity + 1, 0));
  for (var i = 1; i <= n; i++) {
    final [value, weight] = items[i - 1];
    for (var c = 0; c <= capacity; c++) {
      best[i][c] = best[i - 1][c]; // skip item i - 1
      if (weight <= c && best[i - 1][c - weight] + value > best[i][c]) {
        best[i][c] = best[i - 1][c - weight] + value; // take it
      }
    }
  }
  final chosen = <int>[];
  var c = capacity;
  for (var i = n; i > 0; i--) {
    if (best[i][c] != best[i - 1][c]) {
      chosen.add(i - 1);
      c -= items[i - 1][1];
    }
  }
  return [best[n][capacity], chosen.reversed.toList()];
}
```

<!-- CODE:END -->

### Walkthrough

- `best` is an `(n + 1) x (capacity + 1)` table of zeros.
- For each item and each capacity, first copy the "skip" value, then try "take".
- The reconstruction loop goes from the last item back to the first and collects indices; `.reversed` returns them in ascending order.

## Step 6: Dry run of the reconstruction

| i (item) | c | best[i][c] vs best[i-1][c] | taken? | c after |
|---|---|---|---|---|
| 4 ([6, 7]) | 10 | 10 vs 9 | yes (index 3) | 3 |
| 3 ([5, 6]) | 3 | 4 vs 4 | no | 3 |
| 2 ([4, 3]) | 3 | 4 vs 1 | yes (index 1) | 0 |
| 1 ([1, 2]) | 0 | 0 vs 0 | no | 0 |

Chosen: `[1, 3]`, value 10.

## Complexity

- **Time: O(n * c)**.
- **Space: O(n * c)** with reconstruction. If you only need the value, one row of size `c + 1` is enough if you iterate capacities **from high to low** (so each item is used at most once). Iterating from low to high would allow reusing items: that is the **unbounded** knapsack.

This is **pseudo-polynomial**: polynomial in the numeric value of `capacity`, not in the number of bits needed to write it. The 0/1 knapsack problem is NP-hard in general. Saying this is a strong signal.

## Common mistakes

- Greedy by ratio.
- 1D table with the capacity loop in the wrong direction.
- Reconstructing with the wrong index offset (row `i` corresponds to item `i - 1`).

## Follow-ups

1. **Partition Equal Subset Sum (LeetCode #416):** knapsack with boolean values.
2. **Target Sum (#494)**, **Ones and Zeroes (#474, two capacities)**, **Last Stone Weight II (#1049).**
3. **Unbounded knapsack:** Number Of Ways To Make Change, Min Number Of Coins (medium 29, 30), Juice Bottling (hard 25).

## What to remember

0/1 knapsack: `best[i][c] = max(skip, take)` over items and capacities. Reconstruct by checking which rows changed. One-row version: iterate capacity downward.
