# Calendar Matching

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Interval merge + gap finding

## Problem
Two people each give a sorted list of meetings (`["HH:MM", "HH:MM"]`) and their daily bounds (earliest and latest time they are available). Given a meeting duration in minutes, return every time slot of at least that length during which both are free, in military time.

## Building up the logic
1. **Normalize units:** convert all times to minutes since midnight. Time-string arithmetic is a bug factory.
2. **Turn bounds into meetings:** "available from 9:00 to 20:00" is the same as being busy `[0:00, 9:00]` and `[20:00, 24:00]`. Now there is only one kind of data: busy intervals.
3. **Combine:** both people must be free, so a minute is unavailable if **either** is busy. Merge both busy lists into one sorted list (the linear merge step of merge sort, since each input is sorted), then merge overlapping intervals (Merge Overlapping Intervals).
4. **Gaps:** free time is the space between consecutive merged intervals. Keep gaps of at least `duration`.
5. Convert back to `H:MM`.

## Complexity
- Time: O(c1 + c2) (both calendars are already sorted; sorting would add a log factor).
- Space: O(c1 + c2).

## Interview notes
- This is a realistic Google-style problem: most of the work is decomposition into known primitives (normalize, reduce to intervals, merge, find gaps). Narrate those steps before coding.
- LeetCode #1229 (Meeting Scheduler) and #759 (Employee Free Time, k people: heap or merge all).
