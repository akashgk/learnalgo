# Min Number Of Coins For Change

**Difficulty:** Medium | **Category:** Dynamic Programming | **Pattern:** Unbounded knapsack (minimization)

## The problem

Given a target amount `n` and a list of positive coin denominations (unlimited supply), return the **fewest** coins that add up to exactly `n`, or -1 if it is impossible. Making 0 takes 0 coins.

```
n = 7, coins = [1, 5, 10]  ->  3    (5 + 1 + 1)
n = 6, coins = [1, 3, 4]   ->  2    (3 + 3)
n = 3, coins = [2]         ->  -1
```

## Step 1: Why not greedy?

The cashier's method (always take the largest coin that fits) works for US coins, but not in general:

- `n = 6`, coins `[1, 3, 4]`: greedy takes 4, then 1, then 1: **3 coins**. Optimal is 3 + 3: **2 coins**.

Always test a greedy idea against a small counterexample before committing to it. Here it fails, so we need to consider all options: dynamic programming.

## Step 2: Brute force

`minCoins(a) = 1 + min over coins c <= a of minCoins(a - c)`, recursively. The same amounts are recomputed many times: exponential.

## Step 3: The DP

**Subproblem:** `minCoins[a]` = fewest coins to make amount `a`.

**Recurrence:** the **last** coin used is some `c`. Before it, you made `a - c` optimally:

```
minCoins[a] = min over coins c <= a of (minCoins[a - c] + 1)
minCoins[0] = 0
```

Unreachable amounts are "infinity". At the end, infinity means -1.

Loop order does **not** matter for a minimum (unlike counting in medium 29): a minimum does not care whether the same multiset is considered several times.

## Step 4: The code

<!-- CODE:START -->

Full source: [`min_number_of_coins_for_change.dart`](min_number_of_coins_for_change.dart) (run it with `dart run`).

```dart
// Min Number Of Coins For Change (unbounded). minCoins[a] = min(minCoins[a - c] + 1).
// Return -1 if impossible. O(n * d) time, O(n) space.

int minNumberOfCoinsForChange(int n, List<int> denoms) {
  const inf = 1 << 62;
  final minCoins = List<int>.filled(n + 1, inf)..[0] = 0;
  for (final coin in denoms) {
    for (var amount = coin; amount <= n; amount++) {
      final candidate = minCoins[amount - coin] + 1;
      if (minCoins[amount - coin] != inf && candidate < minCoins[amount]) {
        minCoins[amount] = candidate;
      }
    }
  }
  return minCoins[n] == inf ? -1 : minCoins[n];
}
```

<!-- CODE:END -->

### Walkthrough

- `const inf = 1 << 62;` is a large sentinel for "unreachable".
- `minCoins[0] = 0` is the base case.
- For each coin and each amount from `coin` to `n`, try "use this coin last".
- `if (minCoins[amount - coin] != inf && ...)` skips transitions from unreachable amounts. Without this check, `inf + 1` would be treated as a real value (and in other languages could overflow into a negative number).
- The final line converts `inf` to -1.

## Step 5: Dry run

n = 7, coins `[1, 5, 10]`:

| after coin | minCoins[0..7] |
|---|---|
| (start) | 0 inf inf inf inf inf inf inf |
| 1 | 0 1 2 3 4 5 6 7 |
| 5 | 0 1 2 3 4 **1** **2** **3** |
| 10 | unchanged (10 > 7) |

Answer: 3.

And n = 6, coins `[1, 3, 4]`: after coin 1: `0 1 2 3 4 5 6`; after coin 3: `0 1 2 1 2 3 2`; after coin 4: `minCoins[4] = min(2, 0 + 1) = 1`, `minCoins[5] = min(3, 1 + 1) = 2`, `minCoins[6] = min(2, 2 + 1) = 2`. Answer: 2.

## Complexity

- **Time: O(n * d)**.
- **Space: O(n)**.

## Alternative: BFS

Treat amounts as nodes and coins as edges (`a -> a + c`). The fewest coins to reach `n` from 0 is a shortest path in an unweighted graph: BFS. Same worst-case complexity, and it can stop as soon as `n` is reached.

## Common mistakes

- Greedy.
- Initializing with 0 instead of infinity (every amount looks reachable with 0 coins).
- Returning `inf` instead of -1.

## Follow-ups

1. **Coin Change (LeetCode #322):** identical.
2. **Return the coins used:** store which coin achieved each minimum, then walk back from `n`.
3. **Perfect Squares (#279):** coins are 1, 4, 9, 16, ...

## What to remember

"Fewest items to reach an exact total" = unbounded knapsack minimization: `best[a] = 1 + min(best[a - c])`. Beware greedy.
