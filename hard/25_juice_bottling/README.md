# Juice Bottling

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Rod cutting (unbounded knapsack on size)

## The problem

`prices[i]` is the price you get for a bottle containing `i` units of juice (`prices[0] = 0`). You have exactly `prices.length - 1` units and must bottle all of it. Return the list of bottle sizes that **maximizes** total revenue (this solution returns it sorted ascending). Assume a unique optimum.

```
prices = [0, 1, 3, 2]            (3 units)  ->  [1, 2]    revenue 1 + 3 = 4
prices = [0, 1, 6, 10, 11]       (4 units)  ->  [2, 2]    revenue 12
```

## Step 1: This is rod cutting

The classic textbook problem (CLRS chapter 15): cut a rod of length n into pieces to maximize the total price. Units of juice are the rod; bottles are the pieces.

## Step 2: Why greedy fails

"Use the size with the best price per unit": with `prices = [0, 1, 6, 10, 11]`, size 3 has the best ratio (3.33), so greedy sells 3 + 1 for 10 + 1 = **11**. Optimal is 2 + 2 for 6 + 6 = **12**. The best-ratio size can leave an awkward remainder.

## Step 3: The DP

`best[u]` = the maximum revenue from exactly `u` units.

Choose the size `s` of **one** bottle (say, the first one). Then bottle the remaining `u - s` units optimally:

```
best[0] = 0
best[u] = max over s = 1..u of (prices[s] + best[u - s])
```

Record which `s` achieved the maximum (`firstBottle[u]`) to reconstruct the answer: start at `u = n`, take `firstBottle[u]`, subtract it, repeat.

## Step 4: An edge case found by testing

Initialize each `best[u]` with the **one big bottle** option (`prices[u]`, `firstBottle[u] = u`). If instead you start from 0 and only update on strict improvement, then when nothing beats 0 (all prices 0), `firstBottle[u]` stays 0, and the reconstruction loop subtracts 0 forever. The repo's randomized stress test (`tool/stress_test.dart`) caught exactly this bug in an earlier draft. Randomized comparison against a brute force is a technique worth using yourself.

## Step 5: The code

<!-- CODE:START -->

Full source: [`juice_bottling.dart`](juice_bottling.dart) (run it with `dart run`).

```dart
// Juice Bottling (rod cutting): prices[i] = price of a bottle holding i units.
// Total juice = prices.length - 1 units. Maximize revenue; return bottle sizes (ascending).
// O(n^2) time, O(n) space.

List<int> juiceBottling(List<int> prices) {
  final n = prices.length - 1;
  final best = List<int>.filled(n + 1, 0);
  final firstBottle = List<int>.filled(n + 1, 0);
  for (var units = 1; units <= n; units++) {
    // Default: one bottle holding everything. Guarantees a valid (non-zero) first bottle even
    // when no split earns more, e.g. all prices 0; otherwise reconstruction would never end.
    best[units] = prices[units];
    firstBottle[units] = units;
    for (var size = 1; size < units; size++) {
      final revenue = prices[size] + best[units - size];
      if (revenue > best[units]) {
        best[units] = revenue;
        firstBottle[units] = size;
      }
    }
  }
  final sizes = <int>[];
  for (var left = n; left > 0; left -= firstBottle[left]) {
    sizes.add(firstBottle[left]);
  }
  return sizes..sort();
}
```

<!-- CODE:END -->

### Walkthrough

- `n` is the number of units.
- For each `units`, start with the single-bottle option, then try every smaller first bottle.
- The reconstruction subtracts `firstBottle[left]` until nothing is left.
- `sizes..sort()` returns sizes in ascending order.

## Step 6: Dry run: `prices = [0, 1, 3, 2]`

| units | options (first bottle s: price + best[rest]) | best | firstBottle |
|---|---|---|---|
| 1 | s=1: 1 | 1 | 1 |
| 2 | s=2: 3; s=1: 1 + 1 = 2 | 3 | 2 |
| 3 | s=3: 2; s=1: 1 + 3 = **4**; s=2: 3 + 1 = 4 (not better) | 4 | 1 |

Reconstruct: 3 units -> first bottle 1, 2 left -> first bottle 2, 0 left. Sizes `[1, 2]`.

## Complexity

- **Time: O(n^2)**.
- **Space: O(n)**.

## Common mistakes

- Greedy by ratio.
- The zero-progress reconstruction bug described in Step 4.

## Follow-ups

1. **Rod cutting with a cost per cut:** subtract the cost for every cut (every bottle after the first).
2. **Integer Break (LeetCode #343):** split n into parts maximizing the product.
3. **Unbounded knapsack family:** Min Number Of Coins (medium 30), Number Of Ways To Make Change (medium 29).

## What to remember

Rod cutting: `best[u] = max over first piece s of price[s] + best[u - s]`. Initialize with a real option so reconstruction always makes progress.
