# Hand of Straights

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Smallest element must start a group | **Source:** LeetCode 846; NeetCode 150

## The problem

Can the cards be rearranged into groups of `groupSize` **consecutive** values, using every card exactly once?

```
[1, 2, 3, 6, 2, 3, 4, 7, 8], groupSize 3  ->  true   [1,2,3] [2,3,4] [6,7,8]
[1, 2, 3, 4, 5], groupSize 4              ->  false  (5 cards)
```

## Step 1: Quick rejection

If the number of cards is not a multiple of `groupSize`, return false.

## Step 2: The key observation

Look at the **smallest** card, say `x`. Which group can it belong to? A group containing `x` must be `[x, x+1, ..., x+groupSize-1]`: no smaller card exists to start a group that includes `x` in its middle. So `x` **must start** a group, and that group is completely forced.

Remove that group, and apply the same argument to the new smallest card. If any required card is missing, the answer is false. This greedy never makes a choice, so it cannot make a wrong one.

## Step 3: Data structure

We need "smallest remaining value" and "decrement the count of value v" repeatedly. Options:

- a **sorted map** from value to count (Dart `SplayTreeMap`, Java `TreeMap`): `firstKey()` for the minimum;
- or sort the distinct values once and walk them with a count map (each value's remaining count tells how many groups start there).

## Step 4: The code

<!-- CODE:START -->

Full source: [`hand_of_straights.dart`](hand_of_straights.dart) (run it with `dart run`).

```dart
// Hand of Straights: can the cards be split into groups of groupSize consecutive values?
// Greedy from the smallest card: it must START a group (nothing smaller can contain it), so consume
// smallest, smallest + 1, ..., smallest + groupSize - 1. O(n log n) time, O(n) space.

import 'dart:collection';

bool isNStraightHand(List<int> hand, int groupSize) {
  if (hand.length % groupSize != 0) return false;
  final count = SplayTreeMap<int, int>(); // sorted map: firstKey() is the smallest remaining card
  for (final c in hand) {
    count[c] = (count[c] ?? 0) + 1;
  }
  while (count.isNotEmpty) {
    final start = count.firstKey()!;
    for (var v = start; v < start + groupSize; v++) {
      final c = count[v];
      if (c == null) return false; // a gap: this group cannot be completed
      if (c == 1) {
        count.remove(v);
      } else {
        count[v] = c - 1;
      }
    }
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `count` is a `SplayTreeMap`, so `firstKey()` is the smallest remaining card.
- For each value in the forced group, a missing value means false; otherwise decrement and remove at zero (keeping `firstKey()` correct).

## Step 5: Dry run

Counts: 1:1, 2:2, 3:2, 4:1, 6:1, 7:1, 8:1.

| smallest | group | counts after |
|---|---|---|
| 1 | 1 2 3 | 2:1, 3:1, 4:1, 6:1, 7:1, 8:1 |
| 2 | 2 3 4 | 6:1, 7:1, 8:1 |
| 6 | 6 7 8 | empty: **true** |

## Complexity

- Time: **O(n log n)**: each card is decremented once with an O(log n) map operation.
- Space: **O(n)**.

## Edge cases

- `groupSize = 1`: always true.
- Duplicates: counts handle them.

## Common mistakes

- Trying to start groups from arbitrary cards (the smallest card is forced; others are not).
- Using an unsorted hash map and scanning for the minimum each time (O(n^2)).

## Follow-ups you should be ready for

1. **Divide Array in Sets of K Consecutive Numbers (LeetCode 1296).** The same problem.
2. **Split Array into Consecutive Subsequences (LeetCode 659).** Groups of length **at least** 3: greedily extend an existing sequence ending at `x - 1` before starting a new one.
3. **O(n log n) with a sorted array** and a queue of "groups still open" (no tree map needed).

## What to remember

When the smallest element has only one possible role, assign it and repeat. A sorted map of counts gives the smallest remaining element quickly.
