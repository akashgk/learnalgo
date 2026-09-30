# Happy Number

**Difficulty:** Easy | **Category:** Math & Geometry | **Pattern:** Cycle detection on an implicit sequence (Floyd) | **Source:** LeetCode 202; NeetCode 150

## The problem

Replace a positive integer by the sum of the squares of its digits, repeatedly. It is **happy** if the process reaches 1; otherwise it loops forever in a cycle that does not include 1.

```
19 -> 1 + 81 = 82 -> 64 + 4 = 68 -> 36 + 64 = 100 -> 1      happy
2  -> 4 -> 16 -> 37 -> 58 -> 89 -> 145 -> 42 -> 20 -> 4 ...  not happy
```

## Step 1: Why it always either reaches 1 or cycles

For a number with d digits, the next value is at most `81 * d`. For d >= 4, `81 * d` is much smaller than the number itself, so the sequence shrinks quickly; once below 1000 it stays below 243 (`3 * 81`). A sequence confined to a finite set must eventually repeat: it reaches 1 (which maps to itself) or enters a cycle.

## Step 2: Detecting the cycle

**Hash set:** store every value seen; a repeat means a cycle. O(log n) space for the values in practice (bounded by about 243 distinct values plus a short prefix).

**Floyd's tortoise and hare:** the sequence `n, f(n), f(f(n)), ...` is an implicit linked list (like more_problems 08 Find the Duplicate Number and AlgoExpert hard 35 Find Loop). Move `slow` one step and `fast` two steps. If `fast` reaches 1, happy. If they meet elsewhere, there is a cycle without 1. **O(1) space.**

## Step 3: The code

<!-- CODE:START -->

Full source: [`happy_number.dart`](happy_number.dart) (run it with `dart run`).

```dart
// Happy Number: repeatedly replace n by the sum of the squares of its digits. Happy if this reaches
// 1; otherwise it loops forever. Detect the loop with Floyd's fast/slow pointers (O(1) space).
// The sequence quickly drops below 243 (for n < 1000, the next value is at most 3 * 81), so the
// number of steps is O(log n) per iteration and bounded overall.

bool isHappy(int n) {
  var slow = n, fast = _next(n);
  while (fast != 1 && slow != fast) {
    slow = _next(slow);
    fast = _next(_next(fast));
  }
  return fast == 1;
}

int _next(int n) {
  var sum = 0;
  while (n > 0) {
    final d = n % 10;
    sum += d * d;
    n ~/= 10;
  }
  return sum;
}
```

<!-- CODE:END -->

### Walkthrough

- `_next` sums the squared digits using `% 10` and `~/ 10`.
- The loop runs until `fast` hits 1 or the pointers meet. Since 1 maps to itself, if the sequence reaches 1 the pointers eventually meet at 1 as well, so the final check `fast == 1` covers both exits.

## Step 4: Dry run

`n = 19`:

| step | slow | fast |
|---|---|---|
| start | 19 | 82 |
| 1 | 82 | 100 (82 -> 68 -> 100) |
| 2 | 68 | 1 (100 -> 1 -> 1) |

`fast == 1`: **happy**.

## Complexity

- Time: **O(log n)** per step for the digit sum, and a bounded number of steps (the values quickly fall below 243). Commonly stated as O(log n).
- Space: **O(1)** with Floyd.

## Edge cases

- `n = 1`: happy immediately.
- 7 is happy (7 -> 49 -> 97 -> 130 -> 10 -> 1).

## Common mistakes

- Looping until 1 without cycle detection (infinite loop).
- Stopping on the first repeated digit sum without recognizing that 1 is itself a fixed point.

## Follow-ups you should be ready for

1. **Hard-code the cycle.** Every unhappy number enters the cycle containing 4; checking `n == 4` works but is a trick, not a method.
2. **Other functional iterations.** "Does iterating f from x cycle?" is always Floyd or a set.

## What to remember

Repeatedly applying a function defines an implicit linked list. Floyd's tortoise and hare detects the cycle in O(1) space.
