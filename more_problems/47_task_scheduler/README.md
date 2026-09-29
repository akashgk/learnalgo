# Task Scheduler

**Difficulty:** Medium | **Category:** Greedy / Heaps | **Pattern:** Counting argument around the most frequent task | **Source:** LeetCode 621; NeetCode 150

## The problem

Tasks are letters. Each task takes one unit of time. Two runs of the **same** task must be separated by at least `n` units (other tasks or idle time). Tasks may run in any order. Return the minimum total time.

```
tasks = [A, A, A, B, B, B], n = 2  ->  8     A B _ A B _ A B
tasks = [A, C, A, B, D, B], n = 1  ->  6     no idle needed
tasks = [A, A, A, B, B, B], n = 0  ->  6
```

## Step 1: The most frequent task sets the skeleton

Let the most frequent task appear `maxCount` times. Its runs must be at least `n + 1` apart, so lay them out as frames:

```
A _ _ | A _ _ | A          (maxCount = 3, n = 2)
```

There are `maxCount - 1` full frames of length `n + 1`, plus a final partial frame. Every other task fits into the gaps. The total is at least:

```
(maxCount - 1) * (n + 1) + 1
```

If several tasks tie for `maxCount` (here A and B both appear 3 times), each of them also needs a slot in the final frame:

```
A B _ | A B _ | A B        -> (maxCount - 1) * (n + 1) + tiedForMax = 2 * 3 + 2 = 8
```

## Step 2: When there are more tasks than gaps

If there are many different tasks, the gaps fill up and we can simply **extend** frames (a frame may be longer than `n + 1`; the spacing rule only needs "at least n"). Then no idle time is needed at all, and the answer is just the number of tasks.

So:

```
answer = max(tasks.length, (maxCount - 1) * (n + 1) + tiedForMax)
```

**Why can the other tasks always be placed without breaking the rule?** Put the tasks in order of decreasing frequency, filling the frames column by column (all first slots, then all second slots, ...). A task with count `c <= maxCount` lands in `c` different frames, so its copies are at least `n + 1` apart. Tasks with count `maxCount` also get the last partial frame. This is the constructive argument behind the formula.

## Step 3: The simulation alternative

A max-heap of remaining counts plus a cooldown queue: at each time step, run the task with the highest remaining count among those not cooling down. O(T log 26). It is more general (it also produces the schedule) and is a good way to verify the formula; the stress test in this repo compares the two.

## Step 4: The code

<!-- CODE:START -->

Full source: [`task_scheduler.dart`](task_scheduler.dart) (run it with `dart run`).

```dart
// Task Scheduler: tasks (letters) each take one unit; two identical tasks need at least n units
// between them (idle allowed). Minimum total units.
// Counting formula built around the most frequent task. O(T) time, O(1) space (26 counters).

int leastInterval(List<String> tasks, int n) {
  final count = List<int>.filled(26, 0);
  for (final t in tasks) {
    count[t.codeUnitAt(0) - 65]++;
  }
  final maxCount = count.reduce((a, b) => a > b ? a : b);
  final tiedForMax = count.where((c) => c == maxCount).length;
  // (maxCount - 1) full frames of length n + 1, then a final partial frame holding the tied tasks.
  final framed = (maxCount - 1) * (n + 1) + tiedForMax;
  // If there are more tasks than frame slots, no idling is ever needed.
  return framed > tasks.length ? framed : tasks.length;
}
```

<!-- CODE:END -->

### Walkthrough

- Count the tasks per letter (26 counters).
- `maxCount` and `tiedForMax` give the framed length.
- The `max` with `tasks.length` covers the "no idle needed" case.

## Step 5: Dry run

| tasks | n | maxCount | tied | framed | length | answer |
|---|---|---|---|---|---|---|
| AAABBB | 2 | 3 | 2 | 2 * 3 + 2 = 8 | 6 | **8** |
| AAABBB | 0 | 3 | 2 | 2 * 1 + 2 = 4 | 6 | **6** |
| A x 6, B C D E F G | 2 | 6 | 1 | 5 * 3 + 1 = 16 | 12 | **16** |
| AAABBBCCCDDE | 2 | 3 | 3 | 2 * 3 + 3 = 9 | 12 | **12** |

## Complexity

- Time: **O(T)**, T = number of tasks.
- Space: **O(1)** (26 counters).

## Edge cases

- `n = 0`: the answer is the task count.
- One task type: `(count - 1) * (n + 1) + 1`.
- Many distinct tasks: the task count.

## Common mistakes

- Forgetting tasks tied for the maximum count.
- Forgetting the `max` with the task count (the formula alone can be smaller than the number of tasks).
- Simulating with a plain queue in arrival order instead of highest-remaining-first (can be suboptimal).

## Follow-ups you should be ready for

1. **Return the schedule.** Use the heap simulation.
2. **Tasks must run in the given order (LeetCode 2365).** Then it is a simple simulation with "next allowed time" per task.
3. **Reorganize String (LeetCode 767).** The same frame argument with n = 1: possible if and only if `maxCount <= (length + 1) / 2`.

## What to remember

The most frequent task defines the frame structure; ties add to the final frame; if everything fits, the answer is just the number of tasks.
