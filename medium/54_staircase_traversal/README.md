# Staircase Traversal

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** DP with a sliding window sum

## The problem

You climb a staircase of `height` steps, taking between 1 and `maxSteps` steps at a time. Return the number of distinct ways to reach the top. Order matters: `1 + 2` and `2 + 1` are different ways.

```
height = 4, maxSteps = 2  ->  5     (1111, 112, 121, 211, 22)
height = 4, maxSteps = 3  ->  7
```

## Step 1: Think about the last move

To stand on step `h`, your last move came from one of the steps `h - 1, h - 2, ..., h - maxSteps`. The number of ways to reach `h` is therefore the sum of the ways to reach each of those:

```
ways(h) = ways(h-1) + ways(h-2) + ... + ways(h-maxSteps)
ways(0) = 1        (standing at the bottom: one way, the empty sequence)
ways(negative) = 0
```

With `maxSteps = 2` this is exactly Fibonacci.

## Step 2: Plain recursion

Direct translation: exponential, O(maxSteps^height), because the same `ways(k)` is recomputed many times.

## Step 3: Memoization / tabulation

Compute `ways(0), ways(1), ..., ways(height)` in order, each summing up to `maxSteps` previous values: **O(height * maxSteps)** time, O(height) space.

## Step 4: Sliding window sum

Look at consecutive sums:

```
ways(5) = ways(4) + ways(3) + ways(2)       (maxSteps = 3)
ways(6) = ways(5) + ways(4) + ways(3)
```

They share all terms but one at each end. Keep a running `windowSum`: add the newest value entering the window, subtract the one that falls out. Each step is O(1): **O(height)** total.

## Step 5: The code

<!-- CODE:START -->

Full source: [`staircase_traversal.dart`](staircase_traversal.dart) (run it with `dart run`).

```dart
// Staircase Traversal: ways to climb `height` steps taking 1..maxSteps at a time.
// Sliding-window DP: ways[h] = sum of the previous maxSteps values. O(n) time, O(n) space.

int staircaseTraversal(int height, int maxSteps) {
  final ways = List<int>.filled(height + 1, 0)..[0] = 1;
  var windowSum = 0;
  for (var h = 1; h <= height; h++) {
    windowSum += ways[h - 1]; // step that enters the window
    if (h - maxSteps - 1 >= 0) windowSum -= ways[h - maxSteps - 1]; // step that leaves it
    ways[h] = windowSum;
  }
  return ways[height];
}
```

<!-- CODE:END -->

### Walkthrough

- `ways[0] = 1` is the base case.
- At step `h`, `ways[h - 1]` enters the window.
- `if (h - maxSteps - 1 >= 0) windowSum -= ways[h - maxSteps - 1];` removes the value that is now too far back (more than `maxSteps` steps below `h`).
- `ways[h] = windowSum;`

## Step 6: Dry run (height 4, maxSteps 2)

| h | enters | leaves | windowSum = ways[h] |
|---|---|---|---|
| 1 | ways[0] = 1 | | 1 |
| 2 | ways[1] = 1 | | 2 |
| 3 | ways[2] = 2 | ways[0] = 1 | 3 |
| 4 | ways[3] = 3 | ways[1] = 1 | **5** |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Plain recursion | O(k^n) | O(n) |
| Memo / table | O(n * k) | O(n) |
| Sliding window | O(n) | O(n) (O(k) with a circular buffer) |

## Common mistakes

- `ways(0) = 0` (everything becomes 0).
- Off-by-one on which value leaves the window.

## Follow-ups

1. **Climbing Stairs (LeetCode #70):** `maxSteps = 2`.
2. **Allowed step sizes from an arbitrary set** (for example {1, 3, 5}): sum over the allowed sizes; the sliding window no longer applies directly.
3. **Minimum cost climbing stairs (#746):** replace the sum with a min over costs.
4. **Dice Throws (hard 24)** uses the same sliding-window idea.

## What to remember

"Ways to reach n" = sum of ways to reach each state that can move to n. When those states form a contiguous window, maintain a running window sum.
