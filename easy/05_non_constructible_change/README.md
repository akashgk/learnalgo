# Non-Constructible Change

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Sorting + greedy invariant

## The problem

You have a list of coins with positive integer values (duplicates allowed). Return the **smallest amount of change you cannot make** by adding up some subset of the coins. With no coins, the answer is 1.

```
coins = [5, 7, 1, 1, 2, 3, 22]  ->  20
coins = [1, 1, 1, 1, 1]         ->  6
coins = [2]                     ->  1
coins = [1, 2, 4]               ->  8
```

### Clarifying questions

- Can each coin be used at most once? (Yes, it is a subset of the physical coins.)
- Are values positive? (Yes. Zero or negative coins would break the reasoning below.)
- Is the input sorted? (No, and we are allowed to sort.)

## Step 1: Work an example by hand

Sort the coins first because small coins are what build small amounts: `[1, 1, 2, 3, 5, 7, 22]`.

Add coins one at a time and track **every amount you can make so far**:

| Coins used | Amounts you can make |
|---|---|
| (none) | 0 |
| 1 | 0..1 |
| 1, 1 | 0..2 |
| 1, 1, 2 | 0..4 |
| 1, 1, 2, 3 | 0..7 |
| 1, 1, 2, 3, 5 | 0..12 |
| 1, 1, 2, 3, 5, 7 | 0..19 |
| next coin is 22 | 20 is impossible |

Look at the right column. It is always a **contiguous range starting at 0**, and it just grows by the coin's value each time. Until the coin is too big: a 22 would jump from 19 straight past 20, leaving a gap.

## Step 2: Brute force

Generate every subset sum (2^n subsets), put them in a set, and find the smallest positive integer not in it. O(2^n * n) time. Hopeless beyond about 25 coins, but it frames the question: we care about the set of subset sums.

## Step 3: Optimize: find the invariant

From the table, the pattern is:

> **Invariant:** after processing the smallest coins in sorted order, let `change` be their total. Every amount from 1 to `change` can be made.

How does a new coin `c` extend this?

- Every amount in `1..change` can already be made **without** `c`.
- Adding `c` to each of those gives every amount in `c..c + change`.
- The two ranges `1..change` and `c..c + change` join without a gap **exactly when `c <= change + 1`**. Then everything in `1..change + c` is makeable, and the invariant holds with `change += c`.
- If `c > change + 1`, the amount `change + 1` is not makeable: the coins so far sum to only `change`, and `c` alone is already too big. Every later coin is at least `c` (sorted), so `change + 1` stays unmakeable forever. **That is the answer.**

The proof also explains why we sort: the argument "every later coin is at least as big" needs ascending order.

## Step 4: The code

<!-- CODE:START -->

Full source: [`non_constructible_change.dart`](non_constructible_change.dart) (run it with `dart run`).

```dart
// Non-Constructible Change
// Sort coins; keep `change` = every amount in [1, change] is constructible.
// If the next coin > change + 1, then change + 1 is the answer. O(n log n) time, O(1) extra space.

int nonConstructibleChange(List<int> coins) {
  final sorted = [...coins]..sort();
  var change = 0;
  for (final coin in sorted) {
    if (coin > change + 1) break;
    change += coin;
  }
  return change + 1;
}
```

<!-- CODE:END -->

### Walkthrough

- `[...coins]..sort()` sorts a copy (the input stays untouched).
- `var change = 0;` means that with no coins, we can make every amount in `1..0`, i.e. none.
- `if (coin > change + 1) break;` is the gap test from Step 3. `change + 1` is unmakeable.
- `change += coin;` extends the makeable range.
- `return change + 1;` covers both exits: after the break (a gap was found), or after using every coin (the first amount beyond the total).

## Step 5: Dry run

Sorted coins `[1, 1, 2, 3, 5, 7, 22]`:

| coin | change + 1 | coin > change + 1? | change after |
|---|---|---|---|
| 1 | 1 | no | 1 |
| 1 | 2 | no | 2 |
| 2 | 3 | no | 4 |
| 3 | 5 | no | 7 |
| 5 | 8 | no | 12 |
| 7 | 13 | no | 19 |
| 22 | 20 | **yes**, stop | 19 |

Return `19 + 1 = 20`.

## Complexity

- **Time: O(n log n)** for sorting; the scan is O(n).
- **Space: O(1)** extra if you sort in place; O(n) here because the code copies the input.

## Edge cases

| Input | Answer | Reason |
|---|---|---|
| `[]` | 1 | nothing can be made |
| no coin of value 1 | 1 | the first coin already exceeds `0 + 1` |
| `[1, 2, 4]` | 8 | every coin fits, answer is total + 1 |

## Common mistakes

- Forgetting to sort; the invariant proof depends on ascending order.
- Using `coin > change` instead of `coin > change + 1`. With `change = 3` and a coin of 4, the ranges `1..3` and `4..7` do touch, so 4 is fine.
- Returning `change` instead of `change + 1`.

## Follow-ups

1. **Patching Array (LeetCode #330):** add the fewest numbers so every amount up to `n` is makeable. Same invariant; whenever there is a gap, "patch" with `change + 1`, which doubles the range.
2. **Unlimited coins of each value:** a different problem (coin change DP, see medium 29 and 30).

## What to remember

Some greedy problems reduce to a single invariant you can state in one sentence. Here it is "all of `1..change` is makeable". Find the invariant, then show how each step keeps it or breaks it.
