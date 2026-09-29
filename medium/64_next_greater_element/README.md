# Next Greater Element

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Monotonic stack (circular)

## The problem

For each element of an array, find the next element to its right that is **strictly greater**, treating the array as **circular** (after the last element comes the first). Use -1 if there is none.

```
[2, 5, -3, -4, 6, 7, 2]  ->  [5, 6, 6, 6, 7, -1, 5]
```

The last element 2 wraps around and finds 5. The 7 is the maximum: -1.

## Step 1: Brute force

For each index, scan forward (wrapping) up to n - 1 elements for the first bigger one: **O(n^2)**.

## Step 2: The waiting room idea

Walk left to right. Keep the indices that are **still waiting** for their next greater element. When a new value arrives, it answers **every** waiting index whose value is smaller than it. Then the new index starts waiting too.

Which waiting indices does a new value answer? Notice the waiting values are **non-increasing** from oldest to newest: if a newer smaller-or-equal value were waiting behind... more precisely, if an older value were smaller than a newer one, the newer one would already have answered it. So the waiting indices form a **monotonic stack**, and a new value answers a run from the **top** of the stack: pop while the top's value is smaller.

## Step 3: Circularity

The last elements may find their answer near the start. Simply iterate **twice** around the array (`k` from 0 to `2n - 1`, index `k % n`). During the second lap, only answer waiting indices; do not push new ones (every index has already been pushed once).

## Step 4: The code

<!-- CODE:START -->

Full source: [`next_greater_element.dart`](next_greater_element.dart) (run it with `dart run`).

```dart
// Next Greater Element in a circular array (-1 if none).
// Monotonic decreasing stack of indices, iterate twice around. O(n) time, O(n) space.

List<int> nextGreaterElement(List<int> array) {
  final n = array.length;
  final result = List<int>.filled(n, -1);
  final stack = <int>[]; // indices whose next greater element is not found yet
  for (var k = 0; k < 2 * n; k++) {
    final i = k % n;
    while (stack.isNotEmpty && array[stack.last] < array[i]) {
      result[stack.removeLast()] = array[i];
    }
    if (k < n) stack.add(i); // only push each index once
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `result` starts as all -1 (indices never answered keep it).
- `stack` holds indices waiting for an answer.
- `while (stack.isNotEmpty && array[stack.last] < array[i])` pops everything the current value answers.
- `if (k < n) stack.add(i);` pushes only on the first lap.

## Step 5: Dry run

| k | i | value | answers (index: value) | stack after (indices) |
|---|---|---|---|---|
| 0 | 0 | 2 | | 0 |
| 1 | 1 | 5 | 0: 5 | 1 |
| 2 | 2 | -3 | | 1, 2 |
| 3 | 3 | -4 | | 1, 2, 3 |
| 4 | 4 | 6 | 3: 6, 2: 6, 1: 6 | 4 |
| 5 | 5 | 7 | 4: 7 | 5 |
| 6 | 6 | 2 | | 5, 6 |
| 7 | 0 | 2 | (2 is not < 2) | 5, 6 |
| 8 | 1 | 5 | 6: 5 | 5 |
| 9..13 | | | nothing beats 7 | 5 |

Result: `[5, 6, 6, 6, 7, -1, 5]`.

## Complexity

- **Time: O(n)**. The inner `while` looks nested, but every index is pushed once and popped at most once, so the total work across the whole run is O(n) (amortized analysis). Be ready to explain this.
- **Space: O(n)**.

## How to recognize the pattern

"For each element, find the next (or previous) element that is greater (or smaller)" = monotonic stack. Examples:

- Daily Temperatures (LeetCode #739): distance to the next warmer day.
- Online Stock Span (#901): previous greater element.
- Largest Rectangle in Histogram (hard 52): previous and next smaller elements.
- Sunset Views (medium 61).

## Common mistakes

- Pushing values instead of indices (you need the index to write the answer).
- Pushing on the second lap too (duplicates).
- Using `<=` (equal values are not "greater").

## What to remember

A monotonic stack holds elements still waiting for an answer; each new element resolves a run from the top. Twice around the array handles circularity.
