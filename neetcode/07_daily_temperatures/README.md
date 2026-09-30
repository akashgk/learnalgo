# Daily Temperatures

**Difficulty:** Medium | **Category:** Stack | **Pattern:** Monotonic stack (next greater element, as a distance) | **Source:** LeetCode 739; NeetCode 150

## The problem

For each day, return how many days you must wait for a **strictly warmer** temperature, or 0 if it never comes.

```
[73, 74, 75, 71, 69, 72, 76, 73]  ->  [1, 1, 4, 2, 1, 1, 0, 0]
```

This is Next Greater Element (AlgoExpert medium 64) without the circular wrap, returning the **distance** instead of the value.

## Step 1: Brute force

For each day, scan forward for the first warmer day: O(n^2) in the worst case (a decreasing sequence followed by one hot day).

## Step 2: The waiting room

Walk left to right. Keep the days that are **still waiting** for a warmer day. When today arrives, it answers every waiting day that is colder than today.

The waiting temperatures are always **non-increasing** from oldest to newest: if an older waiting day were colder than a newer one, the newer day would have answered it when it arrived. So the waiting days form a stack, and today answers a run from the **top**: pop while the top is colder than today. Then today joins the waiting stack.

Store **indices** on the stack: the answer is a distance, `today - day`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`daily_temperatures.dart`](daily_temperatures.dart) (run it with `dart run`).

```dart
// Daily Temperatures: for each day, how many days until a strictly warmer day (0 if never)?
// Monotonic stack of indices still waiting for a warmer day. O(n) time, O(n) space.

List<int> dailyTemperatures(List<int> temps) {
  final answer = List<int>.filled(temps.length, 0);
  final waiting = <int>[]; // indices; their temperatures are non-increasing from bottom to top
  for (var i = 0; i < temps.length; i++) {
    // Today answers every waiting day that is colder than today.
    while (waiting.isNotEmpty && temps[waiting.last] < temps[i]) {
      final day = waiting.removeLast();
      answer[day] = i - day;
    }
    waiting.add(i);
  }
  return answer;
}
```

<!-- CODE:END -->

### Walkthrough

- `answer` starts at 0, which is correct for days that never get answered.
- `temps[waiting.last] < temps[i]` is strict: an equal temperature is not warmer, so equal days keep waiting.

## Step 4: Dry run

`[73, 74, 75, 71, 69, 72, 76, 73]` (stack shows indices):

| i | temp | popped (answer) | stack after |
|---|---|---|---|
| 0 | 73 | | 0 |
| 1 | 74 | 0 (1) | 1 |
| 2 | 75 | 1 (1) | 2 |
| 3 | 71 | | 2, 3 |
| 4 | 69 | | 2, 3, 4 |
| 5 | 72 | 4 (1), 3 (2) | 2, 5 |
| 6 | 76 | 5 (1), 2 (4) | 6 |
| 7 | 73 | | 6, 7 |

Days 6 and 7 are never popped: 0.

## Complexity

- Time: **O(n)**. Each index is pushed once and popped at most once.
- Space: **O(n)** for the stack in the worst case (decreasing temperatures).

## Edge cases

- Increasing temperatures: every answer is 1, the stack never exceeds one element.
- All equal: all zeros.

## Common mistakes

- Popping on `<=` (treats equal as warmer).
- Storing temperatures instead of indices (cannot compute distances).

## Follow-ups you should be ready for

1. **O(1) extra space.** Iterate from the right; for day i, jump through `j = i + 1, j += answer[j]` until a warmer day or an answer of 0. Amortized O(n).
2. **Online Stock Span (LeetCode 901).** Previous greater-or-equal element, counting days back.
3. **Circular version.** Iterate twice; see AlgoExpert medium 64.

## What to remember

"How long until the next bigger value" is a monotonic stack of indices still waiting for an answer.
