# Sorted Squared Array

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Two pointers from both ends

## The problem

Given an array of integers sorted in ascending order, return a **new** array containing the squares of the original numbers, also sorted in ascending order.

```
[1, 2, 3, 5, 6, 8, 9]      ->  [1, 4, 9, 25, 36, 64, 81]
[-7, -3, 1, 9, 22, 30]     ->  [1, 9, 49, 81, 484, 900]
[-5, -4, -3, -2, -1]       ->  [1, 4, 9, 16, 25]
```

### Clarifying questions

- Can the input contain negatives? (Yes. That is the whole difficulty. With only non-negatives, squaring preserves order and the answer is just "square each element".)
- New array or in place? (New array.)
- Can the numbers be large enough to overflow when squared? (In Java/C++ you would ask about `long`. Dart `int` is 64-bit on native platforms.)

## Step 1: Work an example by hand

`[-7, -3, 1, 9, 22, 30]`. Squares in the same positions: `[49, 9, 1, 81, 484, 900]`.

Look at that sequence. It goes **down** (49, 9, 1) and then **up** (81, 484, 900). Squaring flips the order of the negative part. The squared array is shaped like a valley.

Where is the largest square? At one of the two **ends**, because the largest absolute value is either the most negative number (far left) or the largest positive number (far right). Where is the smallest? Somewhere in the middle, and we do not know where.

That asymmetry is the key: **we always know the largest remaining value, never the smallest.**

## Step 2: Brute force

Square every element, then sort.

```dart
return [for (final x in array) x * x]..sort();
```

- Time: O(n log n) because of the sort.
- Space: O(n) for the output.

It is correct, and in a real codebase it is often fine. But in an interview, an input that is **given sorted** is a hint: the interviewer wants you to use that order and avoid the sort.

## Step 3: Optimize

**Bottleneck:** the sort. Can we produce the output in sorted order directly?

From Step 1: the largest remaining square is always at one of the two ends of the input. So:

1. Put a pointer `lo` at the start and `hi` at the end.
2. Compare `|array[lo]|` and `|array[hi]|`. The bigger one gives the largest remaining square.
3. Write that square into the **last empty slot** of the output, and move that pointer inward.
4. Repeat until the output is full.

Filling the output **from the back** is the trick. If you tried to fill it from the front, you would need the smallest square, which is hidden in the middle of the valley.

## Step 4: The code

<!-- CODE:START -->

Full source: [`sorted_squared_array.dart`](sorted_squared_array.dart) (run it with `dart run`).

```dart
// Sorted Squared Array
// Input is sorted (may contain negatives). The largest square is at one of the two ends,
// so fill the output from the back with two pointers. O(n) time, O(n) output space.

List<int> sortedSquaredArray(List<int> array) {
  final result = List<int>.filled(array.length, 0);
  var lo = 0, hi = array.length - 1;
  for (var write = array.length - 1; write >= 0; write--) {
    final left = array[lo].abs(), right = array[hi].abs();
    if (left > right) {
      result[write] = left * left;
      lo++;
    } else {
      result[write] = right * right;
      hi--;
    }
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `List<int>.filled(array.length, 0)` preallocates the output so we can write to any index, including the back.
- `var lo = 0, hi = array.length - 1;` are the two ends of the part of the input not yet used.
- `for (var write = array.length - 1; write >= 0; write--)` walks the output from the last slot to the first. Each iteration fills exactly one slot, so the loop runs n times.
- `final left = array[lo].abs(), right = array[hi].abs();` compares absolute values, not raw values. Comparing raw values is the most common bug: `-7 < 30` says nothing about which square is bigger.
- The `if/else` writes the bigger square and moves only that pointer. On a tie either choice is fine; the other value is written in the next iteration.

## Step 5: Dry run

`array = [-7, -3, 1, 9, 22, 30]`, output starts as `[0, 0, 0, 0, 0, 0]`:

| write | lo (value) | hi (value) | bigger | output after | move |
|---|---|---|---|---|---|
| 5 | 0 (-7) | 5 (30) | 30 | `[0,0,0,0,0,900]` | hi-- |
| 4 | 0 (-7) | 4 (22) | 22 | `[0,0,0,0,484,900]` | hi-- |
| 3 | 0 (-7) | 3 (9) | 9 | `[0,0,0,81,484,900]` | hi-- |
| 2 | 0 (-7) | 2 (1) | 7 | `[0,0,49,81,484,900]` | lo++ |
| 1 | 1 (-3) | 2 (1) | 3 | `[0,9,49,81,484,900]` | lo++ |
| 0 | 2 (1) | 2 (1) | 1 (tie, else branch) | `[1,9,49,81,484,900]` | hi-- |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Square + sort | O(n log n) | O(n) |
| Two pointers | **O(n)**: one iteration per output slot | O(n) for the output, O(1) extra |

## Edge cases

| Input | Output |
|---|---|
| `[]` | `[]` (loop does not run) |
| `[0]` | `[0]` |
| all negative `[-5, -4, -3]` | `[9, 16, 25]` (the left pointer does all the work) |
| all positive | the right pointer does all the work |

## Common mistakes

- Comparing `array[lo]` and `array[hi]` instead of their absolute values.
- Trying to fill the output from the front (you do not know where the smallest square is).
- Forgetting that the input might be all negative or all positive; the two-pointer version handles both without special cases.

## Follow-ups

1. **Do it in place.** Not possible in O(n) without extra space in general, because values must move to positions that still hold unread input. Say so and explain why.
2. **Merge Sorted Array (LeetCode #88).** Merge `nums2` into `nums1` which has empty space at the end: fill from the back with two pointers, for the same reason.
3. **Apply any convex function** (for example `a*x^2 + b*x + c`, LeetCode #360). The result is still "valley-shaped" (or "hill-shaped" if `a < 0`), so the same two-pointer idea works.

## What to remember

When an operation turns a sorted array into a "valley", the extremes are at the ends: fill the answer from the back with two pointers.
