# Single Cycle Check

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Functional graph traversal with a counting argument

## The problem

Each element of an integer array is a **jump**: from index `i` you move `array[i]` positions forward (or backward if negative), wrapping around the ends. Return whether following the jumps from any index visits every index exactly once and returns to the start: a single cycle through all elements.

```
[2, 3, 1, -4, -4, 2]  ->  true
0 -> 2 -> 3 -> 5 -> 1 -> 4 -> 0   (all six indices, then back to 0)

[1, -1, 1, -1]        ->  false   (0 -> 1 -> 0: stuck in a 2-cycle)
```

## Step 1: Work an example by hand

Start at index 0 of `[2, 3, 1, -4, -4, 2]` (n = 6):

| jump | from | value | to |
|---|---|---|---|
| 1 | 0 | 2 | 2 |
| 2 | 2 | 1 | 3 |
| 3 | 3 | -4 | (3 - 4) wrapped = 5 |
| 4 | 5 | 2 | (5 + 2) wrapped = 1 |
| 5 | 1 | 3 | 4 |
| 6 | 4 | -4 | 0 |

After exactly 6 jumps we are back at 0, and we did not visit 0 in between. All indices were visited.

## Step 2: The graph view

Every index has exactly **one** outgoing edge (its jump). Such a graph is called a **functional graph**. Following edges from any node eventually enters a cycle. The question is whether that cycle contains all n nodes.

## Step 3: A visited array works, but is not needed

The obvious solution marks visited indices and fails on a revisit. O(n) time, O(n) space.

**The O(1)-space counting argument:** start at index 0 and make exactly n jumps.

- If we land on index 0 **before** n jumps, there is a cycle through 0 that is shorter than n: false.
- After n jumps we must be back at index 0; otherwise false.

Why is this enough? If we only return to 0 at jump n, the first n positions (index 0 plus the n - 1 positions before returning) must all be distinct. Suppose some index other than 0 repeated: then we would be trapped in a cycle that does not contain 0 (each index has only one outgoing edge, so after a repeat the path loops forever), and we could never get back to 0. So n distinct positions out of n indices means every index was visited once.

## Step 4: Wrap-around arithmetic

`next = (current + jump) % n`. In Java or C++ the `%` of a negative number is negative, so you would write `((current + jump) % n + n) % n`. In Dart, `%` with a positive divisor always returns a value in `0..n-1`, so `(-1) % 6 == 5` directly.

## Step 5: The code

<!-- CODE:START -->

Full source: [`single_cycle_check.dart`](single_cycle_check.dart) (run it with `dart run`).

```dart
// Single Cycle Check: array of jumps (wrap-around). Is there exactly one cycle visiting
// every index once? Make n jumps; must never revisit index 0 early and must end at 0.
// O(n) time, O(1) space.

bool hasSingleCycle(List<int> array) {
  final n = array.length;
  var visited = 0, idx = 0;
  while (visited < n) {
    if (visited > 0 && idx == 0) return false; // returned to start too early
    visited++;
    idx = (idx + array[idx]) % n; // Dart % is non-negative for positive n
  }
  return idx == 0;
}
```

<!-- CODE:END -->

### Walkthrough

- `visited` counts jumps made so far.
- `if (visited > 0 && idx == 0) return false;` detects an early return to the start.
- `idx = (idx + array[idx]) % n;` makes one jump with wrap-around.
- `return idx == 0;` requires being back at the start after exactly n jumps.

## Complexity

- **Time: O(n)**: exactly n jumps.
- **Space: O(1)**.

## Common mistakes

- Using a visited set and forgetting the "must end at the start" check.
- Negative modulo in languages where it can be negative.
- Checking only that you return to 0 (a smaller cycle through 0 also returns to 0, just too early).

## Follow-ups

1. **Circular Array Loop (LeetCode #457):** find any cycle of length > 1 where all jumps go in the same direction; uses fast/slow pointers on the functional graph.
2. **Find the Duplicate Number (#287):** the array `i -> nums[i]` is a functional graph; Floyd's cycle detection finds the duplicate.

## What to remember

When every node has exactly one outgoing edge, you can reason by counting steps instead of storing visited nodes.
