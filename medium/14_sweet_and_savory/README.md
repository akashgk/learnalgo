# Sweet And Savory

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Split + sort + two pointers

## The problem

Each dish has a non-zero flavor value: **negative** means sweet, **positive** means savory. Pick exactly one sweet dish and one savory dish so that their combined flavor is as close as possible to a `target`, **without going over it**. Return `[sweet, savory]`, or `[0, 0]` if no valid pair exists. Assume at most one best pair.

```
dishes = [-3, -5, 1, 7], target = 8   ->  [-3, 7]   (sum 4)
dishes = [2, 5, -4, -7, 12, 100, -25], target = -20  ->  [-25, 5]  (sum -20)
dishes = [-5, 10], target = 4         ->  [0, 0]    (sum 5 > 4)
```

## Step 1: Work an example by hand

Split the dishes: sweet `[-3, -5]`, savory `[1, 7]`. All pairs: `-3+1 = -2`, `-3+7 = 4`, `-5+1 = -4`, `-5+7 = 2`. The largest sum that does not exceed 8 is 4: `[-3, 7]`.

That is the brute force. To do better, we want a systematic walk where each step rules out a dish for good.

## Step 2: Brute force

Every sweet dish with every savory dish: O(s * v).

## Step 3: Optimize with two pointers

This is "closest pair sum" (like Smallest Difference) with a one-sided constraint. Order the two groups so that one pointer **increases** the sum and the other **decreases** it:

- sweets ordered from closest to zero outward: `-1, -3, -5, ...` (descending). Advancing `i` makes the sweet value more negative, so the sum **decreases**.
- savories ascending: `1, 2, 7, ...`. Advancing `j` makes the sum **increase**.

Start both at the beginning (the sum starts as close to 0 as possible):

- If `sum <= target`: it is a valid candidate; record it if it is closer. Then try to get closer by **increasing** the sum: `j++`.
- If `sum > target`: too big, **decrease** it: `i++`.

**Why is it safe?** When `sum <= target`, the current savory `savory[j]` paired with any later (more negative) sweet gives a smaller sum, which is farther from the target. So `savory[j]` has already produced its best valid pair with this and later sweets: discard it. When `sum > target`, `sweet[i]` with any later (bigger) savory is even bigger, so it cannot produce a valid pair anymore: discard it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`sweet_and_savory.dart`](sweet_and_savory.dart) (run it with `dart run`).

```dart
// Sweet And Savory: sweet dishes are negative, savory positive. Find the pair
// [sweet, savory] whose sum is closest to target without exceeding it; [0, 0] if none.
// Sort sweets by closeness to 0 and savories ascending, then two pointers.
// O(n log n) time, O(n) space.

List<int> sweetAndSavory(List<int> dishes, int target) {
  final sweet = dishes.where((d) => d < 0).toList()..sort((a, b) => b.compareTo(a)); // -1, -3, ...
  final savory = dishes.where((d) => d > 0).toList()..sort(); // 1, 2, ...
  var best = [0, 0];
  var bestGap = double.maxFinite.toInt();
  var i = 0, j = 0;
  while (i < sweet.length && j < savory.length) {
    final sum = sweet[i] + savory[j];
    if (sum <= target) {
      final gap = target - sum;
      if (gap < bestGap) {
        bestGap = gap;
        best = [sweet[i], savory[j]];
      }
      j++; // try a bigger savory to get closer to target
    } else {
      i++; // too big: use a more negative sweet
    }
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `sweet` keeps negatives sorted **descending** (`b.compareTo(a)`), so `-1` comes before `-3`.
- `savory` keeps positives sorted ascending.
- `best = [0, 0]` is the required "no pair" answer.
- The loop implements Step 3; `gap = target - sum` is non-negative for valid pairs, so "closest" means "smallest gap".

## Step 5: Dry run

`dishes = [-3, -5, 1, 7]`, target 8: sweet `[-3, -5]`, savory `[1, 7]`.

| i (sweet) | j (savory) | sum | <= 8? | gap | best | move |
|---|---|---|---|---|---|---|
| 0 (-3) | 0 (1) | -2 | yes | 10 | [-3, 1] | j++ |
| 0 (-3) | 1 (7) | 4 | yes | 4 | [-3, 7] | j++ |
| | savory exhausted | | | | | stop |

Result: `[-3, 7]`.

## Complexity

- **Time: O(n log n)** for sorting; the walk is O(n).
- **Space: O(n)** for the two groups.

## Common mistakes

- Sorting sweets ascending (`-5, -3`) and then moving the wrong pointer.
- Accepting sums above the target.
- Returning `[]` instead of `[0, 0]` when there is no valid pair.

## Follow-ups

1. **Two Sum Less Than K (LeetCode #1099):** same one-sided constraint within one array.
2. **3Sum Closest (#16):** fix one element and run this kind of two-pointer walk.

## What to remember

Arrange two sorted lists so one pointer raises the sum and the other lowers it. Then each comparison tells you exactly which element can be discarded.
