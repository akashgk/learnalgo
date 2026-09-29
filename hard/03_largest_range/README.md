# Largest Range

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Hash set, expand only from run starts

## The problem

Given an array of integers, return `[first, last]` of the **largest range** of consecutive integers that all appear in the array. The numbers do not have to be adjacent or sorted in the input. Assume a unique largest range.

```
[1, 11, 3, 0, 15, 5, 2, 4, 10, 7, 12, 6]  ->  [0, 7]
```

0 through 7 all appear (8 numbers). 10, 11, 12 form a range of 3.

## Step 1: Sorting baseline

Sort, then scan for runs where each value is the previous + 1 (skipping duplicates). **O(n log n).** A good first answer.

## Step 2: Can we avoid sorting?

With all numbers in a **hash set**, "is `x + 1` present?" is O(1). So from any number we can walk upward through its run.

**Problem:** walking from every number repeats work. The run 0..7 would be walked from 0 (8 steps), from 1 (7 steps), from 2, and so on: O(n^2) in the worst case.

## Step 3: Only walk from the start of a run

A number `x` is the **start** of a run exactly when `x - 1` is **not** in the set. Only start walking from such numbers. Every run is then walked exactly once, from its first element.

Total work: each number is the "start" check once (O(1)) and is visited during a walk once. **O(n)** overall, even though there is a loop inside a loop. This amortized argument is what the interviewer wants to hear.

## Step 4: The code

<!-- CODE:START -->

Full source: [`largest_range.dart`](largest_range.dart) (run it with `dart run`).

```dart
// Largest Range: longest run of consecutive integers present in the array (any order).
// Hash set; only start expanding from numbers whose predecessor is absent.
// O(n) time, O(n) space.

List<int> largestRange(List<int> array) {
  final nums = array.toSet();
  var best = [array[0], array[0]];
  for (final x in nums) {
    if (nums.contains(x - 1)) continue; // not the start of a run
    var end = x;
    while (nums.contains(end + 1)) {
      end++;
    }
    if (end - x > best[1] - best[0]) best = [x, end];
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `final nums = array.toSet();` also removes duplicates.
- `if (nums.contains(x - 1)) continue;` skips numbers in the middle of a run.
- The `while` walks up the run from its start.
- `end - x > best[1] - best[0]` compares run lengths.

## Step 5: Dry run

| x | x - 1 present? | walk | range |
|---|---|---|---|
| 1 | yes (0) | skip | |
| 11 | yes (10) | skip | |
| 3 | yes | skip | |
| 0 | no | 0,1,2,3,4,5,6,7 | [0, 7] (length 8) |
| 15 | no | 15 | [15, 15] |
| 10 | no | 10, 11, 12 | [10, 12] |
| others | yes | skip | |

Best: `[0, 7]`.

## Complexity

- **Time: O(n)** (expected, because of hashing).
- **Space: O(n)** for the set.

## Common mistakes

- Walking from every number (O(n^2)).
- Forgetting duplicates in the sorting version.

## Follow-ups

1. **Longest Consecutive Sequence (LeetCode #128):** identical, returns the length. One of the most frequently asked array questions at FAANG.
2. **Union-Find version:** union each x with x + 1 if present; the largest set is the answer. Also near O(n).
3. **Streaming numbers:** maintain run boundaries in a hash map (`start -> end`, `end -> start`) and merge when a new number bridges two runs.

## What to remember

With a hash set, walk sequences only from their natural starting points; that turns a quadratic loop into a linear one.
