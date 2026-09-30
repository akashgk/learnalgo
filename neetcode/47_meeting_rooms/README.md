# Meeting Rooms

**Difficulty:** Easy | **Category:** Intervals | **Pattern:** Sort by start, compare neighbors | **Source:** LeetCode 252 (premium); NeetCode 150

## The problem

Given meeting time intervals `[start, end]`, can one person attend all of them? A meeting ending at `t` and another starting at `t` do not conflict.

```
[[0, 30], [5, 10], [15, 20]]  ->  false
[[7, 10], [2, 4]]             ->  true
```

## Step 1: Brute force

Check every pair for overlap (`a.start < b.end && b.start < a.end`): O(n^2).

## Step 2: Sort, then only neighbors matter

After sorting by start time, if any two meetings overlap, then some **adjacent** pair overlaps. Proof: suppose meeting `i` overlaps a later meeting `j` (so `start[j] < end[i]`). The meeting `i + 1` starts no later than `j`, so `start[i+1] <= start[j] < end[i]`: meeting `i + 1` overlaps meeting `i` too.

So one pass comparing each meeting's start with the previous meeting's end is enough.

## Step 3: The code

<!-- CODE:START -->

Full source: [`meeting_rooms.dart`](meeting_rooms.dart) (run it with `dart run`).

```dart
// Meeting Rooms: can one person attend all meetings (no two overlap)? A meeting ending at t and
// another starting at t do not conflict. Sort by start and check neighbors.
// O(n log n) time, O(n) space for the sorted copy.

bool canAttendMeetings(List<List<int>> intervals) {
  final sorted = [...intervals]..sort((a, b) => a[0].compareTo(b[0]));
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i][0] < sorted[i - 1][1]) return false; // starts before the previous one ends
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- A sorted copy leaves the input unchanged.
- `<` (not `<=`) because back-to-back meetings are allowed.

## Step 4: Dry run

`[[0, 30], [5, 10], [15, 20]]` sorted is the same. Compare `[5, 10]` with `[0, 30]`: 5 < 30, overlap: **false**.

## Complexity

- Time: **O(n log n)**.
- Space: **O(n)** for the copy (O(1) extra if sorting in place is allowed).

## Edge cases

- No meetings or one meeting: true.
- Back-to-back meetings: true.

## Common mistakes

- Comparing only with the first meeting.
- `<=` (treats touching meetings as conflicting).

## Follow-ups you should be ready for

1. **Meeting Rooms II (LeetCode 253): minimum number of rooms.** Sweep line or a min-heap of end times; AlgoExpert hard 32 Laptop Rentals.
2. **Non-overlapping Intervals.** Minimum removals so the rest fit; more_problems 45.
3. **Calendar Matching.** Free slots common to two calendars; AlgoExpert very_hard 2.

## What to remember

After sorting by start, an overlap anywhere implies an overlap between neighbors. One comparison per meeting.
