# Task Assignment

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Sort, then pair smallest with largest

## The problem

You have `k` workers and `2k` tasks, each with a duration. Every worker gets exactly **two** tasks and does them one after the other. Workers run in parallel. Assign tasks to minimize the time until **all** tasks are finished. Return the pairs as **indices** into the original task list.

```
k = 3, tasks = [1, 3, 5, 3, 1, 4]
->  [[0, 2], [4, 5], [1, 3]]      worker times: 1+5 = 6, 1+4 = 5, 3+3 = 6   finish time 6
```

## Step 1: What are we minimizing?

All workers start at time 0, and each finishes after the sum of its two tasks. Everything is done when the **slowest** worker finishes. So we minimize the **maximum pair sum**.

## Step 2: Work an example by hand

Sorted durations: `1, 1, 3, 3, 4, 5`. The longest task (5) must go to somebody, and that worker's time is at least 5 + (its partner). To keep that as small as possible, give it the shortest task: 5 + 1 = 6. Remove both and repeat: 4 + 1 = 5, then 3 + 3 = 6. Maximum 6.

Pairing neighbors instead (`1+1, 3+3, 4+5`) gives a maximum of 9: much worse.

## Step 3: Brute force

Try all ways to split 2k tasks into k pairs: `(2k)! / (2^k * k!)`. Exponential.

## Step 4: Why "smallest with largest" is optimal (exchange argument)

Let `L` be the longest task and `S` the shortest. Suppose an optimal assignment pairs `L` with `x` and `S` with `y`. Since `S` is the shortest, `x >= S`; since `L` is the longest, `y <= L`. Swap partners to get `(L, S)` and `(x, y)`:

- `L + S <= L + x` (because `S <= x`),
- `x + y <= x + L` (because `y <= L`).

Both new pair sums are at most `L + x`, which was already part of the old maximum. So the maximum does not increase. Repeating this argument on the remaining tasks shows the full "smallest with largest" pairing is optimal.

## Step 5: The index detail

The output needs **original indices**, and durations may repeat (two tasks of duration 1). Instead of sorting the durations and then searching for their indices (which needs a value -> list-of-indices map), sort a list of **indices** by duration. Then `order[i]` is directly the index of the i-th shortest task.

## Step 6: The code

<!-- CODE:START -->

Full source: [`task_assignment.dart`](task_assignment.dart) (run it with `dart run`).

```dart
// Task Assignment: 2k tasks, k workers, each does 2 tasks in parallel with others.
// Minimize the slowest worker: pair shortest with longest. Return index pairs.
// O(n log n) time, O(n) space.

List<List<int>> taskAssignment(int k, List<int> tasks) {
  final order = List<int>.generate(tasks.length, (i) => i)
    ..sort((a, b) => tasks[a].compareTo(tasks[b])); // sort indices, keep originals
  return [
    for (var i = 0; i < k; i++) [order[i], order[tasks.length - 1 - i]],
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `List<int>.generate(tasks.length, (i) => i)` creates `[0, 1, ..., 2k - 1]`.
- `..sort((a, b) => tasks[a].compareTo(tasks[b]))` orders indices by their task's duration.
- The comprehension pairs `order[i]` (i-th shortest) with `order[n - 1 - i]` (i-th longest) for `i = 0..k-1`.

## Step 7: Dry run

`tasks = [1, 3, 5, 3, 1, 4]`. Indices sorted by duration: `[0, 4, 1, 3, 5, 2]` (durations `1, 1, 3, 3, 4, 5`; ties may appear in either order).

| i | shortest (idx, dur) | longest (idx, dur) | pair | sum |
|---|---|---|---|---|
| 0 | 0, 1 | 2, 5 | [0, 2] | 6 |
| 1 | 4, 1 | 5, 4 | [4, 5] | 5 |
| 2 | 1, 3 | 3, 3 | [1, 3] | 6 |

Maximum 6. The test checks the maximum and that every task is used exactly once, rather than an exact pair list, because equal durations can be ordered either way.

## Complexity

- **Time: O(n log n)** for sorting (n = 2k).
- **Space: O(n)** for the index list.

## Common mistakes

- Sorting durations and losing the original indices.
- Using `indexOf` to recover indices (returns the same index for duplicate durations).

## Follow-ups

1. **Minimize Maximum Pair Sum in Array (LeetCode #1877):** identical without indices.
2. **Boats to Save People (#881):** pair the heaviest with the lightest if they fit together.
3. **Tandem Bicycle (easy 14):** same pairing family.

## What to remember

To minimize the largest pair sum, pair the smallest remaining with the largest remaining. Sort indices, not values, when the answer needs positions.
