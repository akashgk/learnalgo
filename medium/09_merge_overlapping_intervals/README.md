# Merge Overlapping Intervals

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort by start + sweep

## The problem

Given a list of intervals `[start, end]` in no particular order, merge all overlapping intervals and return the result. Intervals that touch (`[1, 2]` and `[2, 3]`) count as overlapping.

```
[[1, 2], [3, 5], [4, 7], [6, 8], [9, 10]]  ->  [[1, 2], [3, 8], [9, 10]]
[[1, 22], [-20, 30]]                       ->  [[-20, 30]]
```

## Step 1: Work an example by hand

Draw the intervals on a number line:

```
1-2
     3---5
       4-----7
           6---8
                 9-10
```

Reading left to right, `[3, 5]` overlaps `[4, 7]` (4 <= 5), which overlaps `[6, 8]` (6 <= 7). Together they form `[3, 8]`. Once intervals are in order of their start, you only ever need to compare an interval with the **most recent** merged block.

## Step 2: Brute force

Compare every pair; merge any two that overlap; repeat until nothing changes. O(n^2) per round, up to n rounds: O(n^3) in the worst case. Messy and slow.

## Step 3: Optimize: sort, then sweep

1. Sort by start time.
2. Walk through the sorted intervals, keeping the list of merged intervals:
   - If the current interval starts **at or before** the end of the last merged interval, they overlap: extend the last merged interval's end to `max(lastEnd, currentEnd)`.
   - Otherwise, start a new merged interval.

**Why only the last merged interval?** After sorting, the current interval starts at or after every previous start. All earlier merged intervals end before the last merged one begins (otherwise they would have been merged into it), so the current interval cannot reach back to them.

**Why `max`?** Consider `[1, 10]` followed by `[2, 3]`. They overlap, but the merged end must stay 10. Writing `lastEnd = currentEnd` would shrink it to 3. This is the most common bug.

## Step 4: The code

<!-- CODE:START -->

Full source: [`merge_overlapping_intervals.dart`](merge_overlapping_intervals.dart) (run it with `dart run`).

```dart
// Merge Overlapping Intervals. Sort by start, then extend or append.
// O(n log n) time, O(n) space.

List<List<int>> mergeOverlappingIntervals(List<List<int>> intervals) {
  final sorted = [...intervals]..sort((a, b) => a[0].compareTo(b[0]));
  final merged = <List<int>>[];
  for (final [start, end] in sorted) {
    if (merged.isNotEmpty && start <= merged.last[1]) {
      if (end > merged.last[1]) merged.last[1] = end;
    } else {
      merged.add([start, end]);
    }
  }
  return merged;
}
```

<!-- CODE:END -->

### Walkthrough

- `[...intervals]..sort((a, b) => a[0].compareTo(b[0]))` sorts a copy by start.
- `for (final [start, end] in sorted)` destructures each interval with a Dart 3 pattern.
- `start <= merged.last[1]` is the overlap test; `<=` makes touching intervals merge.
- `if (end > merged.last[1]) merged.last[1] = end;` is the `max` rule.
- `merged.add([start, end]);` creates a **new** list, so modifying `merged.last` never mutates the caller's input intervals.

## Step 5: Dry run

Sorted: `[1, 2], [3, 5], [4, 7], [6, 8], [9, 10]`:

| interval | last merged | overlap? | merged after |
|---|---|---|---|
| [1, 2] | none | | [[1, 2]] |
| [3, 5] | [1, 2] | 3 <= 2? no | [[1, 2], [3, 5]] |
| [4, 7] | [3, 5] | 4 <= 5 yes | [[1, 2], [3, 7]] |
| [6, 8] | [3, 7] | 6 <= 7 yes | [[1, 2], [3, 8]] |
| [9, 10] | [3, 8] | 9 <= 8? no | [[1, 2], [3, 8], [9, 10]] |

## Complexity

- **Time: O(n log n)** for sorting; the sweep is O(n).
- **Space: O(n)** for the output (and the sorted copy).

## Edge cases

- One interval: returned as is.
- Containment (`[1, 10], [2, 3]`): the `max` rule.
- Touching intervals: merged because of `<=`. If the interviewer says touching intervals should stay separate, use `<`.

## Common mistakes

- Forgetting to sort.
- Setting the end to the current end instead of the maximum.
- Mutating the input intervals when extending (this code avoids it by copying).

## Follow-ups

1. **Insert Interval (LeetCode #57):** the list is already sorted and non-overlapping; insert one interval in O(n) without re-sorting.
2. **Meeting Rooms (#252):** can one person attend all meetings? Sort and check neighbors.
3. **Meeting Rooms II (#253):** minimum rooms = maximum overlap. See Laptop Rentals (hard 32).
4. **Non-overlapping Intervals (#435):** minimum removals; sort by **end** and greedily keep the earliest-ending intervals.
5. **Calendar Matching (very hard 02):** merge two calendars and find the gaps.

## What to remember

Sort intervals by start; then each interval only needs to be compared with the last merged one, extending its end with `max`.
