# Best Time to Buy and Sell Stock

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Running minimum (one-pass DP) | **Source:** LeetCode 121; Striver A2Z, NeetCode 150

## The problem

`prices[i]` is a stock's price on day `i`. Choose **one** day to buy and a **later** day to sell to maximize profit. If no profit is possible, return 0 (you may simply not trade).

```
[7, 1, 5, 3, 6, 4]  ->  5    (buy at 1 on day 1, sell at 6 on day 4)
[7, 6, 4, 3, 1]     ->  0    (prices only fall; do not trade)
```

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Exactly one transaction, or many? | Many transactions is a different problem (sum every rise). k transactions is AlgoExpert's Max Profit With K Transactions. |
| Must I sell after buying (strictly later day)? | Yes. This is the entire difficulty: without it, the answer is just max - min. |
| Can prices be empty? | Return 0. |

## Step 1: Work an example by hand

`[7, 1, 5, 3, 6, 4]`. The answer is **not** max minus min: the max 7 comes **before** the min 1. The order constraint is the whole problem.

Look at it from the sell side. If I sell on day 4 (price 6), the best buy day is the **cheapest day before day 4**, which is 1. So the profit for selling on day `j` is `prices[j] - min(prices[0..j-1])`. The answer is the best of these over all `j`.

## Step 2: Brute force

Try every pair `i < j`:

```dart
var best = 0;
for (var i = 0; i < n; i++)
  for (var j = i + 1; j < n; j++)
    best = max(best, prices[j] - prices[i]);
```

O(n^2) time, O(1) space.

## Step 3: Optimize

**Duplicated work.** For each `j`, the inner loop recomputes "the minimum of everything before `j`". But the minimum of `prices[0..j]` is just `min(minimum of prices[0..j-1], prices[j])`. We can **carry** it forward in one variable instead of recomputing it.

So one pass keeps two numbers:

- `minPrice`: cheapest price seen so far (the best possible buy for any later day).
- `best`: the best profit found so far.

At each price `p`: first update `minPrice`, then try selling today: `p - minPrice`.

**Why update the minimum before computing the profit?** If `p` is the new minimum, `p - minPrice` becomes 0, which means "buy and sell the same day": zero profit, harmless. The other order also works. Either way you never sell before buying.

This is the simplest example of a pattern you will see everywhere: **the answer for position `j` depends on an aggregate of the prefix, and that aggregate can be updated in O(1)**. Kadane's algorithm is the same idea.

## Step 4: The code

<!-- CODE:START -->

Full source: [`best_time_to_buy_and_sell_stock.dart`](best_time_to_buy_and_sell_stock.dart) (run it with `dart run`).

```dart
// Best Time to Buy and Sell Stock (one transaction).
// Single pass tracking the cheapest price so far. O(n) time, O(1) space.

int maxProfit(List<int> prices) {
  var minPrice = 1 << 62; // cheapest buy seen so far
  var best = 0; // not trading is allowed, so profit never goes below 0
  for (final p in prices) {
    if (p < minPrice) minPrice = p;
    if (p - minPrice > best) best = p - minPrice;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `minPrice = 1 << 62` is effectively infinity, so the first price becomes the minimum.
- `best = 0` encodes "not trading is allowed". If prices only fall, nothing beats 0.
- `if (p < minPrice) minPrice = p;` keeps the cheapest buy available for today and every later day.
- `if (p - minPrice > best) best = p - minPrice;` tries selling today.

## Step 5: Dry run

`[7, 1, 5, 3, 6, 4]`:

| p | minPrice after update | p - minPrice | best |
|---|---|---|---|
| 7 | 7 | 0 | 0 |
| 1 | 1 | 0 | 0 |
| 5 | 1 | 4 | 4 |
| 3 | 1 | 2 | 4 |
| 6 | 1 | 5 | **5** |
| 4 | 1 | 3 | 5 |

## Complexity

| Approach | Time | Space |
|---|---|---|
| All pairs | O(n^2) | O(1) |
| Running minimum | O(n) | O(1) |

## Edge cases

| Input | Expected | Why |
|---|---|---|
| `[]` or one price | 0 | no pair of days |
| strictly decreasing | 0 | every sell is below every earlier buy |
| `[2, 4, 1]` | 2 | the global minimum 1 comes last and cannot be used; the running minimum handles this naturally |

## Common mistakes

- Returning `max - min` without checking the order.
- Initializing `best` to a negative number: the problem allows not trading.
- Tracking the maximum as well and trying to combine "max after min": the running minimum alone is enough.

## Follow-ups you should be ready for

1. **Unlimited transactions (LeetCode 122).** Sum every positive day-to-day difference. Each rise can be captured independently.
2. **At most k transactions (LeetCode 188).** DP over (transactions, day); see very_hard 12 Max Profit With K Transactions.
3. **With cooldown or a fee (LeetCode 309, 714).** State machine DP: hold / not hold (/ cooldown).
4. **Return the days, not the profit.** Also store the index of `minPrice` when `best` improves.

## What to remember

When the answer for index `j` pairs `j` with the best element **before** it, carry that best element in a running variable. One pass, O(1) space.
