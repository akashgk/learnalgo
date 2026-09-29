# First Duplicate Value

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Index as hash (sign marking)

## The problem

You get an array of length n whose values are all integers between 1 and n (inclusive). Return the first value that appears a second time when reading left to right, meaning the value whose **second occurrence has the smallest index**. Return -1 if no value repeats. You may mutate the input.

```
[2, 1, 5, 2, 3, 3, 4]  ->  2
[2, 1, 5, 3, 3, 2, 4]  ->  3   (the second 3 is at index 4, before the second 2 at index 5)
[1, 2, 3]              ->  -1
```

## Step 1: Work an example by hand

Read `[2, 1, 5, 3, 3, 2, 4]` left to right and keep a list of numbers seen: 2, 1, 5, 3, and then **3 again**. The first time you see a number you already saw, that number is the answer. The "first duplicate" is simply the first repeat you encounter while scanning.

So the problem is: "have I seen this value before?", asked n times.

## Step 2: Brute force

For each index `j`, look for an equal value at some index `i < j`. The first `j` with a match gives the answer. **O(n^2)** time, O(1) space.

## Step 3: Hash set (the standard answer)

Keep a set of seen values; return the first value already in the set. **O(n) time, O(n) space.** In most interviews this is already a good answer.

## Step 4: O(1) space: use the array itself as the set

The constraint "values are between 1 and n" is a hint. Every value `v` corresponds to a valid index `v - 1`. We can store one bit of information ("have I seen `v`?") at that index, **without losing the value stored there**, by using the sign:

- To mark `v` as seen: make `array[v - 1]` negative.
- To check whether `v` was seen: test whether `array[v - 1]` is negative.

Because elements might already have been negated, always read `abs()` of the current element to get its actual value.

## Step 5: The code

<!-- CODE:START -->

Full source: [`first_duplicate_value.dart`](first_duplicate_value.dart) (run it with `dart run`).

```dart
// First Duplicate Value: values are in [1, n]. Return the value whose second occurrence
// has the smallest index, or -1. Mark "seen" by negating array[value - 1].
// O(n) time, O(1) extra space (mutates input; restored before returning).

int firstDuplicateValue(List<int> array) {
  var answer = -1;
  for (final raw in array) {
    final value = raw.abs();
    if (array[value - 1] < 0) {
      answer = value;
      break;
    }
    array[value - 1] *= -1;
  }
  for (var i = 0; i < array.length; i++) {
    array[i] = array[i].abs(); // restore the caller's data
  }
  return answer;
}
```

<!-- CODE:END -->

### Walkthrough

- `final value = raw.abs();` recovers the real value even if this position was already negated as a marker.
- `if (array[value - 1] < 0)`: `value` was seen before: it is the first duplicate.
- `array[value - 1] *= -1;` marks `value` as seen.
- The final loop restores every element to its absolute value, so the caller's array is unchanged in the end. Mutating input silently is a code-review red flag; restoring it is good practice.

## Step 6: Dry run

`[2, 1, 5, 2, 3, 3, 4]`:

| raw | value | array[value - 1] before | seen? | array after |
|---|---|---|---|---|
| 2 | 2 | array[1] = 1 | no | [2, -1, 5, 2, 3, 3, 4] |
| -1 | 1 | array[0] = 2 | no | [-2, -1, 5, 2, 3, 3, 4] |
| 5 | 5 | array[4] = 3 | no | [-2, -1, 5, 2, -3, 3, 4] |
| 2 | 2 | array[1] = -1 | **yes** | return 2 |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Hash set | O(n) | O(n) |
| Sign marking | O(n) | O(1) |

## Common mistakes

- Using `array[i]` as an index without `abs()` after it may have been negated (negative index crash).
- Using `value` as the index instead of `value - 1` (values start at 1).
- Forgetting to mention (or undo) the mutation.

## Follow-ups

1. **Find All Duplicates (LeetCode #442)** and **Find All Missing Numbers (#448):** the same sign-marking trick.
2. **First Missing Positive (#41):** a harder "index as hash" problem (place each value at its own index by swapping).
3. **Find the Duplicate Number (#287), array must not be modified:** treat `i -> array[i]` as a linked list and use Floyd's cycle detection (see Find Loop, hard 35).

## What to remember

When values are guaranteed to be valid indices, the array can store "seen" markers itself (sign flips, adding n, or swapping into place) for O(1) extra space.
