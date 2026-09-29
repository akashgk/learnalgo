# Dice Throws

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Counting DP over (items used, total)

## The problem

You roll `numDice` dice, each with faces `1..numSides`. Return the number of distinct outcomes whose faces sum to `target`. Outcomes are **ordered**: die 1 showing 3 and die 2 showing 4 is different from die 1 showing 4 and die 2 showing 3.

```
numDice = 2, numSides = 6, target = 7  ->  6     (1+6, 2+5, 3+4, 4+3, 5+2, 6+1)
```

## Step 1: Brute force

Enumerate all `numSides^numDice` outcomes and count those with the right sum. Exponential in the number of dice.

## Step 2: Think about the last die

The last die shows some face `f` between 1 and `numSides`. The other `numDice - 1` dice must then sum to `target - f`. So:

```
ways(d, t) = sum over f = 1..numSides of ways(d - 1, t - f)
ways(0, 0) = 1         (no dice, total 0: one way)
ways(0, t > 0) = 0
ways(d, t < 0) = 0
```

## Step 3: Tabulate with a rolling row

Row `d` only needs row `d - 1`. Keep one array `ways[t]` for the current number of dice and build the next array from it.

**Speed-up:** `ways(d, t)` sums a **window** of `numSides` consecutive entries of the previous row. Consecutive `t` values share all but two terms, so a running window sum makes each entry O(1) (the same trick as Staircase Traversal). This file uses the simpler O(numSides) inner loop.

## Step 4: The code

<!-- CODE:START -->

Full source: [`dice_throws.dart`](dice_throws.dart) (run it with `dart run`).

```dart
// Dice Throws: number of ways to roll `numDice` dice with `numSides` sides summing to target.
// DP over dice with a rolling array. O(d * t * s) time, O(t) space.
// (A sliding-window sum makes it O(d * t).)

int diceThrows(int numDice, int numSides, int target) {
  var ways = List<int>.filled(target + 1, 0)..[0] = 1; // 0 dice: one way to make 0
  for (var d = 1; d <= numDice; d++) {
    final next = List<int>.filled(target + 1, 0);
    for (var t = 1; t <= target; t++) {
      for (var face = 1; face <= numSides && face <= t; face++) {
        next[t] += ways[t - face];
      }
    }
    ways = next;
  }
  return ways[target];
}
```

<!-- CODE:END -->

### Walkthrough

- `ways` starts as the row for 0 dice: `ways[0] = 1`.
- For each die, `next[t]` sums `ways[t - face]` for every face that fits (`face <= t`).
- `ways = next;` moves to the next row.

## Step 5: Dry run (2 dice, 6 sides, target 7)

| dice | ways[0..7] |
|---|---|
| 0 | 1 0 0 0 0 0 0 0 |
| 1 | 0 1 1 1 1 1 1 0 |
| 2 | 0 0 1 2 3 4 5 **6** |

`ways2[7] = ways1[6] + ways1[5] + ... + ways1[1] = 6`.

## Complexity

- **Time: O(d * t * s)** as written; **O(d * t)** with the sliding window.
- **Space: O(t)**.

## Common mistakes

- `ways(0, 0) = 0` (then everything is 0).
- Counting combinations instead of ordered outcomes (this DP naturally counts ordered outcomes).
- Overflow for large inputs: Dart's `int` wraps silently past 2^63. LeetCode's version asks for the answer modulo 10^9 + 7; apply `%` after every addition.

## Follow-ups

1. **Number of Dice Rolls With Target Sum (LeetCode #1155).**
2. **Probability instead of count:** divide by `numSides^numDice`, or run the DP with probabilities.
3. **Combinations instead of ordered outcomes:** loop faces outside, like Number Of Ways To Make Change.

## What to remember

"Number of ways to reach a total with k items" = DP over (items used, total), summing over the choice for the last item.
