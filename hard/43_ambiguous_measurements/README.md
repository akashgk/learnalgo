# Ambiguous Measurements

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Memoized recursion over a range state

## The problem

You have measuring cups, but they are imprecise: filling cup `i` produces an unknown amount somewhere in `[low_i, high_i]`. You pour whole cups (any cup, any number of times) into one container. Given a target range `[low, high]`, return whether some sequence of pours **guarantees** that the total ends up inside the target range, no matter where each individual pour lands within its cup's range.

```
cups = [[200, 210], [450, 465], [800, 850]], target = [2100, 2300]  ->  true
one guaranteed combination: 800-850 + 2 x (450-465) + 2 x (200-210) = [2100, 2200]
```

## Step 1: Model the uncertainty as an interval

Pouring cups with ranges `[l1, h1]`, `[l2, h2]`, ... produces a total anywhere in `[l1 + l2 + ..., h1 + h2 + ...]`. The total is **guaranteed** to be in the target iff that whole interval fits inside `[low, high]`:

```
sum of lows >= low     and     sum of highs <= high
```

So the question is: is there a multiset of cups whose low-sum and high-sum satisfy both inequalities?

## Step 2: Recursive formulation

Pick one cup `c` to pour first. What must the **remaining** pours achieve? If the rest totals `[restLow, restHigh]`, we need:

- `c.low + restLow >= low`, i.e. `restLow >= low - c.low`;
- `c.high + restHigh <= high`, i.e. `restHigh <= high - c.high`.

So the remaining problem is the same problem with the new target `[low - c.low, high - c.high]`. Deriving the new bounds from **both** inequalities is the key step.

**Base cases and pruning:**

- If a single cup already fits (`c.low >= low` and `c.high <= high`), success.
- If `c.high >= high` and it does not fit alone, pouring it leaves no room for anything else: skip it.
- A lower bound below zero is clamped to 0 (you have already guaranteed enough).

`high` strictly decreases with every pour (cup ranges are positive), so the recursion terminates.

## Step 3: Memoization

Many pour orders reach the same remaining target (`A then B` and `B then A`). The answer depends only on `(low, high)`, so cache results by that pair.

## Step 4: The code

<!-- CODE:START -->

Full source: [`ambiguous_measurements.dart`](ambiguous_measurements.dart) (run it with `dart run`).

```dart
// Ambiguous Measurements: each cup, when filled, yields an amount in [low, high].
// Can a combination of fills guarantee a total within [low, high] target range?
// Memoized recursion over (targetLow, targetHigh). O(low * high * n) time, O(low * high) space.

bool ambiguousMeasurements(List<List<int>> cups, int low, int high) {
  final memo = <(int, int), bool>{};

  /// Can pours whose combined total is guaranteed to land in [lo, hi] be chosen?
  bool canMeasure(int lo, int hi) {
    final key = (lo, hi);
    final cached = memo[key];
    if (cached != null) return cached;
    var ok = false;
    for (final [cupLow, cupHigh] in cups) {
      if (cupLow >= lo && cupHigh <= hi) {
        ok = true; // this single pour is guaranteed to finish inside the range
        break;
      }
      if (cupHigh >= hi) continue; // pouring it leaves no room for anything else
      // After this pour, the rest must land in [lo - cupLow, hi - cupHigh] (lower clamped to 0).
      if (canMeasure(lo - cupLow > 0 ? lo - cupLow : 0, hi - cupHigh)) {
        ok = true;
        break;
      }
    }
    return memo[key] = ok;
  }

  return canMeasure(low, high);
}
```

<!-- CODE:END -->

### Walkthrough

- `memo` is keyed by the record `(lo, hi)`.
- For each cup: success if it fits alone; skip if it would use up all the room; otherwise recurse on the reduced target.
- The result is stored before returning.

## Step 5: Small dry run: cups `[[5, 7]]`

- Target `[10, 14]`: the cup does not fit alone (7 <= 14 but 5 < 10). `7 < 14`, so recurse with `[10 - 5, 14 - 7] = [5, 7]`. Now the cup fits alone (5 >= 5 and 7 <= 7): **true**. Two pours give `[10, 14]`.
- Target `[10, 13]`: recurse with `[5, 6]`. The cup does not fit alone (7 > 6), and `7 >= 6` so it is skipped: **false**. Two pours give `[10, 14]`, which could overshoot 13.

## Complexity

- **Time: O(low * high * n)** in the worst case: at most `low * high` distinct states, each trying n cups.
- **Space: O(low * high)** for the memo, plus recursion depth.

## Common mistakes

- Using the midpoint or the low end of each cup (ignores the "guarantee").
- Deriving only one of the two new bounds.

## What to remember

Turn uncertain quantities into intervals, derive the reduced target from both interval inequalities, and memoize on the reduced target.
