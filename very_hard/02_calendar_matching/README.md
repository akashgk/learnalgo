# Calendar Matching

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Normalize, merge intervals, find gaps

## The problem

Two people each give:

- a sorted list of meetings as `["HH:MM", "HH:MM"]` pairs,
- their daily bounds: the earliest and latest times they are available.

Given a meeting duration in minutes, return every time slot of **at least** that duration during which **both** are free, in `H:MM` format.

```
calendar1 = [["9:00", "10:30"], ["12:00", "13:00"], ["16:00", "18:00"]], bounds1 = ["9:00", "20:00"]
calendar2 = [["10:00", "11:30"], ["12:30", "14:30"], ["14:30", "15:00"], ["16:00", "17:00"]], bounds2 = ["10:00", "18:30"]
duration  = 30
->  [["11:30", "12:00"], ["15:00", "16:00"], ["18:00", "18:30"]]
```

## Step 1: Decompose into known pieces

This problem looks messy, but it is a chain of simple steps. Saying the decomposition out loud before coding is most of the interview:

1. **Normalize** times to minutes since midnight (string time arithmetic is a bug factory).
2. **Turn bounds into meetings:** "available from 9:00 to 20:00" is the same as being busy from 0:00 to 9:00 and from 20:00 to 24:00. Now there is only one kind of data: busy intervals.
3. **Combine both people:** a minute is unavailable if **either** person is busy. So take all busy intervals of both people together.
4. **Merge** overlapping busy intervals (Merge Overlapping Intervals, medium 09).
5. **Gaps** between consecutive merged intervals are the common free time. Keep the gaps of at least `duration`.
6. Convert back to `H:MM`.

## Step 2: Combining sorted lists

Each calendar is already sorted. Combining two sorted lists into one sorted list is the linear **merge step of merge sort**; no need to sort again (sorting would also work, at O(n log n)).

## Step 3: The code

<!-- CODE:START -->

Full source: [`calendar_matching.dart`](calendar_matching.dart) (run it with `dart run`).

```dart
// Calendar Matching: two people's meetings and daily bounds ("HH:MM"). Return all free slots
// of at least `duration` minutes available to both. Convert to minutes, add bound blocks,
// merge all busy intervals, collect gaps. O(c1 + c2) time and space (inputs are sorted).

List<List<String>> calendarMatching(
  List<List<String>> calendar1,
  List<String> dailyBounds1,
  List<List<String>> calendar2,
  List<String> dailyBounds2,
  int meetingDuration,
) {
  int toMin(String t) {
    final [h, m] = t.split(':').map(int.parse).toList();
    return h * 60 + m;
  }

  String toTime(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

  List<List<int>> withBounds(List<List<String>> cal, List<String> bounds) => [
    [0, toMin(bounds[0])], // busy before the day starts
    for (final [s, e] in cal) [toMin(s), toMin(e)],
    [toMin(bounds[1]), 24 * 60], // busy after the day ends
  ];

  final a = withBounds(calendar1, dailyBounds1), b = withBounds(calendar2, dailyBounds2);
  // Merge the two sorted lists (like merge sort), then merge overlapping intervals.
  final all = <List<int>>[];
  var i = 0, j = 0;
  while (i < a.length || j < b.length) {
    if (j == b.length || (i < a.length && a[i][0] <= b[j][0])) {
      all.add(a[i++]);
    } else {
      all.add(b[j++]);
    }
  }
  final merged = <List<int>>[];
  for (final [s, e] in all) {
    if (merged.isNotEmpty && s <= merged.last[1]) {
      if (e > merged.last[1]) merged.last[1] = e;
    } else {
      merged.add([s, e]);
    }
  }
  return [
    for (var k = 1; k < merged.length; k++)
      if (merged[k][0] - merged[k - 1][1] >= meetingDuration) [toTime(merged[k - 1][1]), toTime(merged[k][0])],
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `toMin` parses `"H:MM"` with a list pattern; `toTime` formats minutes back, padding the minutes to two digits.
- `withBounds` wraps a calendar with the two "busy outside bounds" intervals.
- The `while` loop merges the two sorted lists.
- The next loop merges overlapping intervals (touching counts as overlapping).
- The final comprehension emits gaps of at least `meetingDuration`.

## Step 4: Dry run (in minutes)

Person 1 busy (with bounds): `[0,540] [540,630] [720,780] [960,1080] [1200,1440]`.
Person 2 busy (with bounds): `[0,600] [600,690] [750,870] [870,900] [960,1020] [1110,1440]`.

Merged busy intervals:

| merged | covers |
|---|---|
| [0, 690] | until 11:30 |
| [720, 900] | 12:00 to 15:00 |
| [960, 1080] | 16:00 to 18:00 |
| [1110, 1440] | from 18:30 |

Gaps: 690-720 (30 min), 900-960 (60 min), 1080-1110 (30 min). All are at least 30: `11:30-12:00`, `15:00-16:00`, `18:00-18:30`.

## Complexity

- **Time: O(c1 + c2)** (both calendars are already sorted).
- **Space: O(c1 + c2)**.

## Common mistakes

- Forgetting the daily bounds (returns slots at 3 AM).
- Doing arithmetic on `"HH:MM"` strings.
- Treating touching meetings (`12:30-14:30` and `14:30-15:00`) as leaving a gap of 0 that is then reported.

## Follow-ups

1. **Meeting Scheduler (LeetCode #1229):** return the earliest common slot of a given length.
2. **Employee Free Time (#759):** k people; merge all intervals (with a heap for sorted lists) and find the gaps.
3. **Time zones:** normalize everyone to UTC first.

## What to remember

Real-world scheduling problems decompose into: normalize units, express everything as intervals, merge, then read off the gaps.
