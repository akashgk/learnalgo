# Monotonic Array

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Single pass with two hypotheses

## The problem

An array is monotonic if its elements, from left to right, are entirely **non-increasing** or entirely **non-decreasing**. Equal neighbors are allowed. Return whether a given array is monotonic. Empty and one-element arrays are monotonic.

```
[-1, -5, -10, -1100, -1100, -1101, -1102, -9001]  ->  true   (non-increasing)
[1, 1, 2, 3, 4, 5, 5, 5, 6, 7, 8, 7, 9, 10, 11]   ->  false  (8 -> 7 breaks it)
[1, 1, 1]                                          ->  true
```

## Step 1: Work an example by hand

For `[1, 1, 2, 3, ..., 8, 7, 9]`: the first change you see is `1 -> 2` (up), so the array would have to be non-decreasing. Later `8 -> 7` goes down: not monotonic.

Subtlety: the first pair `1, 1` tells you nothing. Direction is only decided by the first **unequal** pair. That is where naive solutions break.

## Step 2: Approach A: decide the direction first

1. Find the first index where `a[i] != a[i-1]`. That decides "increasing" or "decreasing".
2. Check that no later pair goes the other way.

Correct, but you must handle arrays where all elements are equal, and the "find direction" loop adds code paths where bugs hide.

## Step 3: Approach B: keep both hypotheses alive (this code)

Start by assuming **both** directions are possible:

- `nonDecreasing = true`, `nonIncreasing = true`.
- Any strict **decrease** (`a[i] < a[i-1]`) disproves "non-decreasing".
- Any strict **increase** disproves "non-increasing".
- Equal neighbors disprove nothing.

At the end, the array is monotonic if at least one hypothesis survived. Exit early once both are dead.

This "assume every possibility, eliminate on evidence" pattern avoids special cases entirely. It is worth remembering.

## Step 4: The code

<!-- CODE:START -->

Full source: [`monotonic_array.dart`](monotonic_array.dart) (run it with `dart run`).

```dart
// Monotonic Array: entirely non-increasing or entirely non-decreasing.
// Track both possibilities in one pass. O(n) time, O(1) space.

bool isMonotonic(List<int> array) {
  var nonDecreasing = true, nonIncreasing = true;
  for (var i = 1; i < array.length; i++) {
    if (array[i] < array[i - 1]) nonDecreasing = false;
    if (array[i] > array[i - 1]) nonIncreasing = false;
    if (!nonDecreasing && !nonIncreasing) return false;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- Two booleans record which directions are still possible.
- The loop compares each element with its predecessor.
- `if (!nonDecreasing && !nonIncreasing) return false;` is the early exit.
- `return true;`: at least one direction survived (both survive for constant arrays).

## Step 5: Dry run

`[1, 2, 2, 1]`:

| i | pair | nonDecreasing | nonIncreasing |
|---|---|---|---|
| 1 | 1 -> 2 (up) | true | false |
| 2 | 2 -> 2 (equal) | true | false |
| 3 | 2 -> 1 (down) | false | false -> return false |

## Complexity

- **Time: O(n)**, one pass.
- **Space: O(1)**.

## Common mistakes

- Deciding direction from `a[0]` and `a[1]` when they are equal.
- Treating equal neighbors as a violation (the problem allows them).
- Comparing `a[0]` with `a[n-1]` to decide direction: works for monotonic arrays but still requires a full check; easy to get wrong.

## Follow-ups

1. **Strictly monotonic:** treat equality as a violation of both hypotheses.
2. **Longest monotonic subarray:** track current increasing and decreasing run lengths; reset on violations.
3. **Streaming data:** the two-flag approach already works one element at a time.

## What to remember

When you do not know which case applies, track all cases at once and eliminate them as evidence arrives.
