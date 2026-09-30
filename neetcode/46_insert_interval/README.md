# Insert Interval

**Difficulty:** Medium | **Category:** Intervals | **Pattern:** Three-phase linear scan | **Source:** LeetCode 57; NeetCode 150, Blind 75

## The problem

`intervals` is sorted by start and non-overlapping. Insert `newInterval`, merging any intervals it overlaps, and return the result (still sorted and non-overlapping). Touching endpoints (`[1, 5]` and `[5, 7]`) overlap.

```
[[1,3], [6,9]], [2,5]                              ->  [[1,5], [6,9]]
[[1,2], [3,5], [6,7], [8,10], [12,16]], [4,8]      ->  [[1,2], [3,10], [12,16]]
```

## Step 1: Simple approach

Append the new interval, sort by start, run Merge Intervals (AlgoExpert medium 9): O(n log n). Correct, but it ignores that the input is already sorted.

## Step 2: Three phases, one pass

Because the intervals are sorted and disjoint, they fall into three consecutive groups relative to the new interval `[start, end]`:

1. **Entirely before it:** `interval.end < start`. Copy them unchanged.
2. **Overlapping it:** `interval.start <= end` (and not in group 1). Absorb each into the new interval: `start = min(...)`, `end = max(...)`.
3. **Entirely after it:** everything left. Copy unchanged.

Add the merged new interval between groups 1 and 3.

**Why is group 2 contiguous?** The intervals are sorted and disjoint, so once an interval starts after `end`, every later one does too.

## Step 3: The code

<!-- CODE:START -->

Full source: [`insert_interval.dart`](insert_interval.dart) (run it with `dart run`).

```dart
// Insert Interval: intervals are sorted by start and non-overlapping. Insert newInterval, merging
// where needed. Three phases in one scan: intervals entirely before it, overlapping ones (merged
// into it), intervals entirely after it. O(n) time, O(n) space for the output.

List<List<int>> insert(List<List<int>> intervals, List<int> newInterval) {
  final result = <List<int>>[];
  var i = 0;
  var start = newInterval[0], end = newInterval[1];
  // 1. Ends before the new interval starts: untouched.
  while (i < intervals.length && intervals[i][1] < start) {
    result.add(intervals[i++]);
  }
  // 2. Starts before (or when) the new interval ends: overlaps, so absorb it.
  while (i < intervals.length && intervals[i][0] <= end) {
    if (intervals[i][0] < start) start = intervals[i][0];
    if (intervals[i][1] > end) end = intervals[i][1];
    i++;
  }
  result.add([start, end]);
  // 3. Everything else starts after the merged interval ends.
  while (i < intervals.length) {
    result.add(intervals[i++]);
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- Phase 1 uses `<` so an interval ending exactly at `start` counts as overlapping (touching merges).
- Phase 2 uses `<=` for the same reason at the other end.
- `end` grows during phase 2, so the loop keeps absorbing intervals that overlap the **growing** interval.

## Step 4: Dry run

`[[1,2], [3,5], [6,7], [8,10], [12,16]]`, new `[4, 8]`:

| interval | phase | merged interval |
|---|---|---|
| [1, 2] | 1 (2 < 4): copy | [4, 8] |
| [3, 5] | 2 (3 <= 8): absorb | [3, 8] |
| [6, 7] | 2 (6 <= 8): absorb | [3, 8] |
| [8, 10] | 2 (8 <= 8): absorb | [3, 10] |
| [12, 16] | 3 (12 > 10): copy | |

Result: `[[1, 2], [3, 10], [12, 16]]`.

## Complexity

- Time: **O(n)**.
- Space: **O(n)** for the output.

## Edge cases

- Empty list: just the new interval.
- New interval before all or after all: phases 2 empty.
- New interval covering everything: phases 1 and 3 empty.

## Common mistakes

- Using the new interval's **original** end in phase 2 (must use the growing `end`).
- Off-by-one on touching endpoints.
- Mutating the input intervals while merging.

## Follow-ups you should be ready for

1. **Many insertions.** Keep intervals in a balanced BST (or `SplayTreeMap` keyed by start): each insertion is O(log n + merged count).
2. **Remove an interval.** Split overlapping intervals into up to two pieces.
3. **Merge Intervals.** AlgoExpert medium 9.

## What to remember

In a sorted, disjoint interval list, a new interval splits the list into "before", "overlapping" (a contiguous run), and "after". One pass handles all three.
