# Best Time to Buy and Sell Stock with Cooldown

**Difficulty:** Medium | **Category:** 2-D Dynamic Programming | **Pattern:** State machine DP | **Source:** LeetCode 309; NeetCode 150

## The problem

Unlimited transactions, holding at most one share at a time. After you **sell**, you cannot buy on the next day (a one-day cooldown). Maximize profit.

```
[1, 2, 3, 0, 2]  ->  3    buy 1, sell 2, cooldown, buy 0, sell 2
```

## Step 1: Why the simple rules fail

Without cooldown, the answer is the sum of all positive day-to-day differences. Here, taking a small profit today can block a better buy tomorrow, so decisions interact. The state must remember whether we are allowed to buy.

## Step 2: Define the states

At the end of each day we are in exactly one of three states:

| State | Meaning |
|---|---|
| `hold` | holding a share |
| `sold` | sold today (so tomorrow is a cooldown) |
| `rest` | not holding, and free to buy tomorrow |

Transitions from one day to the next, with today's price `p`:

```
hold' = max(hold,       rest - p)   // keep holding, or buy today (only from rest)
sold' = hold + p                    // sell today
rest' = max(rest, sold)             // stay out, or yesterday's sale finishes its cooldown
```

Each variable is the **best profit** achievable while ending the day in that state.

Why can you only buy from `rest`, not from `sold`? Being in `sold` at the end of yesterday means you sold yesterday, so today is the cooldown.

Initial day: `hold = -prices[0]` (bought on day 0), `rest = 0`, and `sold = 0`. Selling on day 0 is impossible, but 0 is a safe placeholder: `sold` only feeds `rest' = max(rest, sold)` and the final answer, and `rest` is already 0.

The answer is `max(sold, rest)`: ending while holding a share is never better than not having bought it.

## Step 3: The code

<!-- CODE:START -->

Full source: [`best_time_to_buy_and_sell_stock_with_cooldown.dart`](best_time_to_buy_and_sell_stock_with_cooldown.dart) (run it with `dart run`).

```dart
// Best Time to Buy and Sell Stock with Cooldown: unlimited transactions, one share at a time, and
// after a sell you must wait one day before buying again.
// State machine DP over three states at the end of each day:
//   hold  = holding a share
//   sold  = just sold today (so tomorrow is a cooldown)
//   rest  = not holding, free to buy tomorrow
// O(n) time, O(1) space.

int maxProfit(List<int> prices) {
  if (prices.isEmpty) return 0;
  var hold = -prices[0], sold = 0, rest = 0;
  for (var i = 1; i < prices.length; i++) {
    final p = prices[i];
    final newHold = hold > rest - p ? hold : rest - p; // keep holding, or buy (only from rest)
    final newSold = hold + p; // sell today
    final newRest = rest > sold ? rest : sold; // stay out, or finish yesterday's cooldown
    hold = newHold;
    sold = newSold;
    rest = newRest;
  }
  return sold > rest ? sold : rest; // ending while holding is never better
}
```

<!-- CODE:END -->

### Walkthrough

- All three new values are computed from the **old** values before any is overwritten.
- The return ignores `hold`.

## Step 4: Dry run

`[1, 2, 3, 0, 2]`:

| day | price | hold | sold | rest |
|---|---|---|---|---|
| 0 | 1 | -1 | 0 | 0 |
| 1 | 2 | -1 | 1 | 0 |
| 2 | 3 | -1 | 2 | 1 |
| 3 | 0 | 1 | -1 | 2 |
| 4 | 2 | 1 | **3** | 2 |

On day 3, `hold = rest - 0 = 1`: buying at 0 after resting is allowed because `rest` on day 2 came from selling on day 1 (cooldown on day 2 is over). Answer `max(3, 2) = 3`.

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Empty or single price: 0.
- Decreasing prices: 0 (never buy).

## Common mistakes

- Allowing a buy from `sold` (ignores the cooldown).
- Updating variables in place so a new value is used in the same day's other transitions.
- Returning `hold` or forgetting `rest` in the answer.

## Follow-ups you should be ready for

1. **With a transaction fee (LeetCode 714).** Two states: `hold`, `free`; subtract the fee when selling.
2. **At most k transactions (LeetCode 188).** States indexed by the number of transactions; AlgoExpert very_hard 12.
3. **Draw the state machine.** Interviewers often ask for the diagram: three nodes, arrows labeled buy / sell / rest.

## What to remember

Stock problems with rules are state machines. Name the states at the end of each day, write each state's best value from yesterday's states, and update all of them together.
