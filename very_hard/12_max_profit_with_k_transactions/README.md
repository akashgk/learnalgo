# Max Profit With K Transactions

**Difficulty:** Very Hard | **Category:** Dynamic Programming | **Pattern:** 2D DP with a running-max optimization

## The problem

Given a list of daily stock prices and an integer k, return the maximum profit you can make with **at most k transactions**. A transaction is one buy followed later by one sell. You can hold at most one share at a time (you must sell before buying again).

```
prices = [5, 11, 3, 50, 60, 90], k = 2  ->  93
buy at 5, sell at 11 (+6); buy at 3, sell at 90 (+87)
```

## Step 1: Define the subproblem

`P[t][d]` = the maximum profit using **at most t transactions**, considering only days `0..d`.

## Step 2: Recurrence: what happens on day d?

1. **Do not sell on day d:** the profit is `P[t][d - 1]`.
2. **Sell on day d**, having bought on some earlier day `x < d`. Before day x you could have completed at most `t - 1` transactions, earning `P[t - 1][x]`. The profit is:

```
prices[d] - prices[x] + P[t - 1][x]
```

So:

```
P[t][d] = max( P[t][d-1],
               prices[d] + max over x < d of (P[t-1][x] - prices[x]) )
```

Base cases: `P[0][*] = 0` (no transactions), `P[*][0] = 0` (one day: no profit).

Evaluated naively, the inner `max over x` makes it **O(k * n^2)**.

## Step 3: Remove the inner loop

For a fixed `t`, the inner term `max over x < d of (P[t-1][x] - prices[x])` gains exactly **one** new candidate each time `d` increases (the candidate `x = d - 1`). So keep it as a running variable `bestBuy` ("the best position after buying"), updating it once per day. Each cell is then O(1): **O(k * n)**.

## Step 4: Space

Row `t` only needs row `t - 1`: keep two rows, **O(n)** space.

## Step 5: The code

<!-- CODE:START -->

Full source: [`max_profit_with_k_transactions.dart`](max_profit_with_k_transactions.dart) (run it with `dart run`).

```dart
// Max Profit With K Transactions (buy then sell, at most k times, no overlapping holdings).
// profit[t][d] = max(profit[t][d-1], prices[d] + max_{x<d}(profit[t-1][x] - prices[x])).
// The inner max is tracked incrementally. O(n * k) time, O(n) space (two rows).

int maxProfitWithKTransactions(List<int> prices, int k) {
  if (prices.isEmpty || k == 0) return 0;
  var prev = List<int>.filled(prices.length, 0); // t - 1 transactions
  for (var t = 1; t <= k; t++) {
    final curr = List<int>.filled(prices.length, 0);
    var bestBuy = -prices[0]; // max over x < d of prev[x] - prices[x]
    for (var d = 1; d < prices.length; d++) {
      final sellToday = prices[d] + bestBuy;
      curr[d] = curr[d - 1] > sellToday ? curr[d - 1] : sellToday;
      final buyToday = prev[d] - prices[d];
      if (buyToday > bestBuy) bestBuy = buyToday;
    }
    prev = curr;
  }
  return prev.last;
}
```

<!-- CODE:END -->

### Walkthrough

- `prev` is row `t - 1` (starts as all zeros: no transactions).
- For each `t`, `bestBuy` starts as `prev[0] - prices[0]` (buying on day 0).
- For each day: selling today gives `prices[d] + bestBuy`; not selling keeps `curr[d - 1]`. Then day `d` becomes a buy candidate: `prev[d] - prices[d]`.
- The answer is the last cell of the last row.

## Step 6: Dry run

| row | values for days 0..5 |
|---|---|
| t = 0 | 0, 0, 0, 0, 0, 0 |
| t = 1 | 0, 6, 6, 47, 57, 87 |
| t = 2 | 0, 6, 6, 53, 63, **93** |

In row 2 at day 3: `bestBuy` has become `prev[2] - prices[2] = 6 - 3 = 3` (one completed transaction worth 6, then buying at 3). Selling at 50 gives 53; later at 90 gives 93.

## Complexity

- **Time: O(n * k)**.
- **Space: O(n)**.

**Shortcut for large k:** if `k >= n / 2`, the limit can never bind (a transaction needs at least 2 days). Then just add every positive day-to-day increase: O(n). Mention this; it prevents a huge k from blowing up the table.

## Common mistakes

- Allowing a sell and a buy on the same day in a way that double-counts.
- Forgetting the running-max trick and settling for O(k * n^2).

## The stock problem family (one mental model)

| Problem | Constraint |
|---|---|
| LeetCode #121 | 1 transaction: track min price so far |
| #122 | unlimited: sum all positive differences |
| #123 | 2 transactions: four state variables (buy1, sell1, buy2, sell2) |
| #188 | k transactions: this problem |
| #309 | cooldown after selling: states hold / sold / rest |
| #714 | transaction fee: subtract the fee when selling |

All of them are "state machine" DPs over (day, transactions used, holding or not).

## What to remember

`P[t][d] = max(P[t][d-1], prices[d] + max over x<d of (P[t-1][x] - prices[x]))`. The inner max only grows by one candidate per day, so track it in a variable.
