# Laptop Rentals

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Maximum interval overlap (min-heap of end times, or sweep line)

## The problem

A school lends laptops to students. Each rental is an interval `[start, end)`. A laptop returned at time `t` can be handed to a student whose rental starts at time `t`. Return the **minimum number of laptops** the school needs.

```
[[0, 2], [1, 4], [4, 6], [0, 4], [7, 8], [9, 11], [3, 10]]  ->  3
```

## Step 1: Reframe the question

The school needs as many laptops as the **maximum number of rentals active at the same moment**. At any moment, every active rental needs its own laptop; and when fewer are active, laptops can always be reused.

In the example, at time 3 the rentals `[1,4]`, `[0,4]`, `[3,10]` are all active: 3 laptops. No moment has 4.

## Step 2: Approach A: min-heap of end times

1. Sort rentals by start time.
2. Keep a min-heap of the end times of laptops currently in use.
3. For each rental: if the earliest end in the heap is `<= start`, that laptop is free: pop it (reuse). Push this rental's end.
4. The heap size never needs to exceed the answer; the maximum heap size is the answer (equivalently, the final heap size, since we only pop when reusing).

**O(n log n).**

## Step 3: Approach B: sweep line (this code)

Only the **count** of active rentals matters, not which rental holds which laptop. So separate the events:

1. Sort all start times, and separately all end times.
2. Walk through the starts in order. Before counting a start at time `s`, retire every end time `<= s` (those laptops come back).
3. Track the maximum number in use.

The `<=` encodes the rule "returned at t can be reused at t". With closed intervals it would be `<`.

**O(n log n)**, no heap needed.

## Step 4: The code

<!-- CODE:START -->

Full source: [`laptop_rentals.dart`](laptop_rentals.dart) (run it with `dart run`).

```dart
// Laptop Rentals: min laptops so every [start, end) interval gets one (a laptop freed at t can
// be reused by a rental starting at t). Sweep over sorted starts and ends.
// O(n log n) time, O(n) space.

int laptopRentals(List<List<int>> times) {
  final starts = [for (final t in times) t[0]]..sort();
  final ends = [for (final t in times) t[1]]..sort();
  var inUse = 0, best = 0, e = 0;
  for (final s in starts) {
    while (e < ends.length && ends[e] <= s) {
      e++; // a laptop was returned before or exactly when this rental starts
      inUse--;
    }
    inUse++;
    if (inUse > best) best = inUse;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `starts` and `ends` are sorted separately.
- `e` points to the next end time not yet retired.
- For each start, retire ends, then take a laptop (`inUse++`), then update the maximum.

## Step 5: Dry run

Starts: `0, 0, 1, 3, 4, 7, 9`. Ends: `2, 4, 4, 6, 8, 10, 11`.

| start | ends retired (<= start) | inUse | best |
|---|---|---|---|
| 0 | | 1 | 1 |
| 0 | | 2 | 2 |
| 1 | | 3 | 3 |
| 3 | 2 | 3 | 3 |
| 4 | 4, 4 | 2 | 3 |
| 7 | 6 | 2 | 3 |
| 9 | 8 | 2 | 3 |

Answer: 3.

## Complexity

- **Time: O(n log n)** for sorting.
- **Space: O(n)**.

## Common mistakes

- Using `<` where the problem allows reuse at the same instant (or vice versa).
- Sorting intervals by end time for this question (that is the greedy for a different problem: choosing the most non-overlapping intervals).

## Follow-ups

1. **Meeting Rooms II (LeetCode #253):** identical. One of the most common interval questions at Google, Meta, and Amazon.
2. **Car Pooling (#1094):** each trip has a passenger count; sweep with weighted events.
3. **My Calendar (#729/#731/#732):** online booking with overlap limits.

## What to remember

"Minimum resources for overlapping intervals" = maximum overlap. Compute it with a min-heap of end times, or by sweeping sorted starts and ends.
