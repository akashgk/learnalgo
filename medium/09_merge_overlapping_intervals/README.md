# Merge Overlapping Intervals

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Sort by start + sweep

## Problem
Given a list of `[start, end]` intervals (unsorted), merge every group of overlapping intervals and return the result. Touching intervals (`[1,2]` and `[2,3]`) overlap.

## Building up the logic
1. Unsorted, any interval might overlap any other: O(n^2) comparisons with repeated merging.
2. After sorting by start, an interval can only overlap the **last merged** interval. Why: all earlier merged intervals end before the last one starts (otherwise they would have been merged), and the current interval starts after them.
3. Sweep: if `start <= last.end`, extend `last.end = max(last.end, end)`; otherwise start a new merged interval.
4. The `max` is essential. `[1,10]` then `[2,3]` must stay `[1,10]`. Forgetting it is the most common bug.

## Complexity
- Time: O(n log n) sort + O(n) sweep.
- Space: O(n) for the output (and sort copy).

## Interview notes
- Interval problems at FAANG are frequent: Insert Interval (#57), Meeting Rooms I/II (#252/#253, use a min-heap of end times or sweep line), Non-overlapping Intervals (#435, sort by end, greedy), Calendar Matching and Laptop Rentals in this repo.
- Clarify whether touching intervals merge. It changes `<=` to `<`.
