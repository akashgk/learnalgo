# Non-overlapping Intervals

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Interval scheduling (sort by end) | **Source:** LeetCode 435; Striver A2Z, NeetCode 150

## The problem

Return the minimum number of intervals to remove so that the rest do not overlap. Intervals that only touch (`[1, 2]` and `[2, 3]`) do not overlap.

```
[[1,2], [2,3], [3,4], [1,3]]  ->  1    (remove [1,3])
[[1,2], [1,2], [1,2]]         ->  2
[[1,2], [2,3]]                ->  0
```

## Step 1: Reformulate

"Remove the fewest" = "**keep the most** non-overlapping intervals", then `removed = n - kept`. Keeping the maximum number of compatible intervals is the classic **activity selection** (interval scheduling) problem.

## Step 2: Which greedy?

Several greedy rules sound plausible. Test them:

| Rule | Counterexample |
|---|---|
| Earliest start first | `[1, 100]` starts first and blocks `[2, 3]`, `[4, 5]`, ... |
| Shortest first | `[1, 5]`, `[4, 7]`, `[6, 10]`: shortest is `[4, 7]`, which blocks both others (keeps 1, optimum is 2) |
| Fewest conflicts first | known counterexamples exist; also expensive |
| **Earliest end first** | correct |

## Step 3: Why earliest end is optimal (exchange argument)

Sort by end. Let `g` be the interval that ends first. Take any optimal solution `O`, and let `o` be its interval that ends first. Since `g` ends no later than `o`, replacing `o` with `g` in `O` cannot create an overlap: everything else in `O` starts at or after `o`'s end, hence at or after `g`'s end. So there is an optimal solution containing `g`. Remove `g` and every interval overlapping it, and repeat the argument on what remains.

Intuition: the interval that frees up the timeline soonest leaves the most room for everything else.

## Step 4: The algorithm

Sort by end. Track `lastEnd`, the end of the last kept interval. For each interval in order: if it starts at or after `lastEnd`, keep it and update `lastEnd`; otherwise, it overlaps a kept interval, so it is removed.

## Step 5: The code

<!-- CODE:START -->

Full source: [`non_overlapping_intervals.dart`](non_overlapping_intervals.dart) (run it with `dart run`).

```dart
// Non-overlapping Intervals: minimum number of intervals to remove so the rest do not overlap
// (touching endpoints like [1,2] and [2,3] do not overlap).
// Greedy: sort by END, keep every interval that starts at or after the last kept end.
// O(n log n) time, O(n) space for the sorted copy.

int eraseOverlapIntervals(List<List<int>> intervals) {
  if (intervals.isEmpty) return 0;
  final sorted = [...intervals]..sort((a, b) => a[1].compareTo(b[1]));
  var kept = 0, lastEnd = -(1 << 62);
  for (final iv in sorted) {
    if (iv[0] >= lastEnd) {
      kept++; // the earliest-finishing compatible interval leaves the most room for the rest
      lastEnd = iv[1];
    }
  }
  return intervals.length - kept;
}
```

<!-- CODE:END -->

### Walkthrough

- A sorted copy avoids mutating the input.
- `lastEnd` starts very negative so the first interval is always kept.
- `iv[0] >= lastEnd` uses `>=` because touching intervals are allowed.

## Step 6: Dry run

`[[1,2], [2,3], [3,4], [1,3]]`, sorted by end: `[1,2], [2,3], [1,3], [3,4]` (the two intervals ending at 3 may come in either order; the result is the same).

| interval | start >= lastEnd? | kept | lastEnd |
|---|---|---|---|
| [1,2] | yes (vs -inf) | 1 | 2 |
| [2,3] | 2 >= 2 yes | 2 | 3 |
| [1,3] | 1 >= 3 no (removed) | 2 | 3 |
| [3,4] | 3 >= 3 yes | 3 | 4 |

Removed: 4 - 3 = **1**.

## Complexity

- Time: **O(n log n)** for sorting.
- Space: **O(n)** for the sorted copy (O(1) extra if sorting in place is allowed).

## Edge cases

- Empty: 0.
- All identical intervals: keep one.
- Nested intervals: the inner one ends first and is kept.

## Common mistakes

- Sorting by start and keeping the first (wrong greedy).
- Using `>` instead of `>=` (touching intervals counted as overlapping).
- Sorting by start is fine **only** with the extra rule "on overlap, keep the one with the smaller end". That is equivalent but easier to get wrong.

## Follow-ups you should be ready for

1. **Minimum Number of Arrows to Burst Balloons (LeetCode 452).** Same greedy; touching counts as overlapping there, so the comparison becomes `>`.
2. **Meeting Rooms II / minimum platforms (Striver).** A different question: how many resources are needed at once. See AlgoExpert hard 32 Laptop Rentals.
3. **Weighted intervals (maximize total weight).** Greedy fails; DP over intervals sorted by end with binary search for the last compatible one.

## What to remember

To keep the most non-overlapping intervals, sort by **end** and keep every interval compatible with the last kept one. Prove it with an exchange argument.
