# Best Seat

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Scan runs of free cells

## The problem

A row of seats is given as an array: `1` means taken, `0` means free. The first and last seats are always taken. You want the free seat that gives you the most space: its distance to the **nearest** taken seat should be as large as possible. On ties, pick the lowest index. Return the seat index, or -1 if every seat is taken.

```
[1, 0, 1, 0, 0, 0, 1]  ->  4
[1, 0, 1]              ->  1
[1, 1, 1]              ->  -1
```

## Step 1: Work an example by hand

In `[1, 0, 1, 0, 0, 0, 1]` there are two groups of free seats between taken ones:

- Group at index 1 (one free seat): sitting there, your nearest neighbor is 1 seat away.
- Group at indices 3, 4, 5 (three free seats): the middle seat, index 4, is 2 seats from the nearest neighbor on both sides.

The best seat is the middle of the "best" group. So the problem is really about **runs of consecutive free seats**.

## Step 2: Brute force

For every free seat, scan left and right to the nearest taken seat and take the minimum distance. O(n^2) in the worst case (long runs are scanned repeatedly).

## Step 3: Optimize: reason about runs

Within a run of `k` free seats bounded by taken seats, the best seat is its middle, and its distance to the nearest taken seat is `ceil(k / 2) = (k + 1) ~/ 2`:

| run length k | best distance |
|---|---|
| 1 | 1 |
| 2 | 1 |
| 3 | 2 |
| 4 | 2 |
| 5 | 3 |

So a single pass that finds each run (jump from one taken seat to the next) is enough. For each run, compute its best distance and keep the best overall. If two runs give the same distance, keep the earlier one (strict `>`), which also gives the lower index.

For an even run, two middle seats are equally good; `(left + right) ~/ 2` picks the lower one, matching the tie rule.

## Step 4: The code

<!-- CODE:START -->

Full source: [`best_seat.dart`](best_seat.dart) (run it with `dart run`).

```dart
// Best Seat: seats[i] is 1 (taken) or 0 (free); both ends are taken. Pick the free seat
// whose distance to the nearest taken seat is largest; ties go to the lowest index.
// Return -1 if no seat is free. O(n) time, O(1) space.

int bestSeat(List<int> seats) {
  var best = -1, bestDistance = 0;
  var left = 0;
  while (left < seats.length) {
    var right = left + 1;
    while (right < seats.length && seats[right] == 0) {
      right++;
    }
    // Free run is (left, right), exclusive. Its middle seat is farthest from both ends.
    final freeCount = right - left - 1;
    final distance = (freeCount + 1) ~/ 2; // distance from the middle to the nearer end
    if (freeCount > 0 && distance > bestDistance) {
      bestDistance = distance;
      best = (left + right) ~/ 2;
    }
    left = right;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `left` always points to a taken seat (index 0 is taken by definition).
- The inner loop moves `right` to the next taken seat. The free run is strictly between `left` and `right`.
- `freeCount = right - left - 1` is the run length.
- `distance = (freeCount + 1) ~/ 2` is the best distance in this run.
- `best = (left + right) ~/ 2` is the middle seat (lower of two middles for even runs).
- `left = right;` jumps to the next taken seat, so each seat is visited once.

## Step 5: Dry run

`[1, 0, 1, 0, 0, 0, 1]`:

| left | right | freeCount | distance | best, bestDistance |
|---|---|---|---|---|
| 0 | 2 | 1 | 1 | 1, 1 |
| 2 | 6 | 3 | 2 | 4, 2 |
| 6 | 7 (end) | 0 | | unchanged |

Answer: 4.

## Complexity

- **Time: O(n)**: `left` and `right` only move forward.
- **Space: O(1)**.

## A note on the definition

AlgoExpert's reference solution ranks runs by their **length**, which can prefer a longer run whose middle is **not** actually farther from neighbors (runs of 3 and 4 both give distance 2). This version ranks by real distance, which matches the stated goal. In an interview, ask which one is intended; the test `[1, 0, 0, 0, 1, 0, 0, 0, 0, 1] -> 2` shows the difference.

## Common mistakes

- Choosing the longest run instead of the largest distance.
- Off-by-one when computing the run length or the middle.

## Follow-ups

1. **Maximize Distance to Closest Person (LeetCode #849):** the ends may be free. A run touching the left or right end has distance `k` (sit at the far end), not `ceil(k/2)`.
2. **Exam Room (#855):** people arrive and leave repeatedly; maintain the runs in an ordered set or a heap keyed by distance.

## What to remember

When the answer depends on gaps between markers, iterate marker to marker and reason about each gap as a whole.
