# Car Fleet

**Difficulty:** Medium | **Category:** Stack | **Pattern:** Sort by position, compare arrival times | **Source:** LeetCode 853; NeetCode 150

## The problem

`n` cars drive toward `target` on a one-lane road. Car `i` starts at `position[i]` with speed `speed[i]`. A car can never pass another; when a faster car catches up, it slows down and they drive together as one **fleet** (a car that catches up exactly at the target also joins). How many fleets arrive?

```
target = 12, position = [10, 8, 0, 5, 3], speed = [2, 4, 1, 1, 3]  ->  3
```

## Step 1: Simulation is messy

You could simulate time steps, but catch-up moments happen at fractional times, and merging cars mid-road is fiddly. Look for something simpler.

## Step 2: Only arrival times matter

Compute each car's arrival time **if the road were empty**: `(target - position) / speed`.

Process cars from the one **closest to the target** backward. The car ahead of the current car has already been assigned to a fleet, and that fleet arrives at some time `T` (the time of its slowest, leading car).

- If the current car would arrive **later** than `T` (`time > T`), it never catches up: it leads a **new** fleet, and `T` becomes its time.
- Otherwise (`time <= T`), it would catch up at or before the target: it **joins** the fleet ahead and arrives at `T` too, so `T` does not change.

**Why only the fleet directly ahead?** A car can only interact with the car in front of it. If it cannot catch the fleet directly ahead, it cannot catch anything further ahead either (that fleet blocks it).

This is often written with a stack of fleet arrival times; the count of pushes equals the count of fleets. One variable is enough.

## Step 3: The code

<!-- CODE:START -->

Full source: [`car_fleet.dart`](car_fleet.dart) (run it with `dart run`).

```dart
// Car Fleet: cars on a one-lane road drive toward target. A faster car that catches a slower one
// ahead slows down and joins it (a fleet). How many fleets arrive?
// Sort by position (closest to the target first) and compare arrival times. O(n log n) time.

int carFleet(int target, List<int> position, List<int> speed) {
  final order = List.generate(position.length, (i) => i)..sort((a, b) => position[b].compareTo(position[a]));
  var fleets = 0;
  var slowestAhead = 0.0; // arrival time of the fleet directly ahead
  for (final i in order) {
    final time = (target - position[i]) / speed[i]; // arrival time if the road were empty
    // Arriving strictly later than the fleet ahead means it never catches up: a new fleet.
    // Arriving earlier or at the same time means it catches up and joins that fleet.
    if (time > slowestAhead) {
      fleets++;
      slowestAhead = time;
    }
  }
  return fleets;
}
```

<!-- CODE:END -->

### Walkthrough

- `order` sorts indices by position, descending (closest to the target first).
- `slowestAhead` is the arrival time of the fleet directly ahead, starting at 0 (no fleet yet).
- `time > slowestAhead` creates a new fleet; equal times merge, matching the rule that catching up exactly at the target counts as one fleet.

## Step 4: Dry run

target 12:

| position | speed | time | vs fleet ahead | fleets | slowestAhead |
|---|---|---|---|---|---|
| 10 | 2 | 1 | 1 > 0: new | 1 | 1 |
| 8 | 4 | 1 | 1 > 1? no: joins | 1 | 1 |
| 5 | 1 | 7 | 7 > 1: new | 2 | 7 |
| 3 | 3 | 3 | 3 > 7? no: joins | 2 | 7 |
| 0 | 1 | 12 | 12 > 7: new | **3** | 12 |

## Complexity

- Time: **O(n log n)** for sorting.
- Space: **O(n)** for the index order.

## Edge cases

- One car: one fleet.
- Everyone catches the car closest to the target: one fleet.
- Floating point: `(target - position) / speed` is a double. IEEE division is correctly rounded, so two mathematically equal times give identical doubles, and with LeetCode's limits (values up to 10^6) distinct times differ by far more than rounding error. To avoid the question entirely, compare `(target - p1) * s2` with `(target - p2) * s1` as integers.

## Common mistakes

- Sorting by position ascending (then you do not know the fleet ahead yet).
- Comparing against the car directly ahead's own time instead of its fleet's time.
- Treating "arrives at the same time" as a separate fleet.

## Follow-ups you should be ready for

1. **Car Fleet II (LeetCode 1776).** Return each car's collision time: monotonic stack from the right with collision time comparisons.
2. **Integer-only comparison.** Cross-multiply to avoid floating point.

## What to remember

Sort by distance to the target; each car either joins the fleet directly ahead (arrives no later) or starts a new one. Arrival times replace simulation.
