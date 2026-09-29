# Selection Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Repeated minimum selection

## The problem

Sort an array of integers in ascending order using Selection Sort, and return it.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: The idea

Find the smallest element and put it first. Find the smallest of the rest and put it second. Continue until one element is left.

**Invariant:** before step `start`, `array[0..start-1]` holds the `start` smallest elements, in sorted order, in their final positions.

## Step 2: Work an example by hand

| start | unsorted part | minimum (index) | swap | array after |
|---|---|---|---|---|
| 0 | [8, 5, 2, 9, 5, 6, 3] | 2 (2) | 8 <-> 2 | [2, 5, 8, 9, 5, 6, 3] |
| 1 | [5, 8, 9, 5, 6, 3] | 3 (6) | 5 <-> 3 | [2, 3, 8, 9, 5, 6, 5] |
| 2 | [8, 9, 5, 6, 5] | 5 (4) | 8 <-> 5 | [2, 3, 5, 9, 8, 6, 5] |
| 3 | [9, 8, 6, 5] | 5 (6) | 9 <-> 5 | [2, 3, 5, 5, 8, 6, 9] |
| 4 | [8, 6, 9] | 6 (5) | 8 <-> 6 | [2, 3, 5, 5, 6, 8, 9] |
| 5 | [8, 9] | 8 (5) | none | unchanged |

## Step 3: The code

<!-- CODE:START -->

Full source: [`selection_sort.dart`](selection_sort.dart) (run it with `dart run`).

```dart
// Selection Sort (in place). Repeatedly select the minimum of the unsorted suffix and swap
// it to the front. O(n^2) always, O(1) space, at most n - 1 swaps. Not stable.

List<int> selectionSort(List<int> array) {
  for (var start = 0; start < array.length - 1; start++) {
    var minIdx = start;
    for (var i = start + 1; i < array.length; i++) {
      if (array[i] < array[minIdx]) minIdx = i;
    }
    if (minIdx != start) {
      final tmp = array[start];
      array[start] = array[minIdx];
      array[minIdx] = tmp;
    }
  }
  return array;
}
```

<!-- CODE:END -->

### Walkthrough

- `for (var start = 0; start < array.length - 1; start++)`: the last element needs no step; once everything else is placed, it is the maximum.
- The inner loop finds `minIdx`, the position of the smallest value in `array[start..]`.
- The swap only happens when needed (`minIdx != start`).

## Complexity

- **Time: O(n^2) in every case.** Even for sorted input, it scans the full remainder to confirm the minimum: `(n-1) + (n-2) + ... + 1` comparisons.
- **Space: O(1)**.
- **Swaps: at most n - 1.** This is Selection Sort's only real advantage: minimal writes, useful when writing is expensive (for example, flash memory).

### Not stable

The long-distance swap can jump an element over an equal one. Example: `[5a, 5b, 2]`. Step 0 swaps `5a` with `2`: `[2, 5b, 5a]`. The two 5s changed order. (At step 1 in the table above, the swap moved the first `5` from index 1 to index 6, behind the other `5`.)

## Selection Sort vs Heap Sort

Selection Sort spends O(n) finding each minimum. **Heap Sort (hard 49) is Selection Sort where a heap finds the extreme in O(log n)**, giving O(n log n). Remembering this link makes both algorithms easier to recall.

## What to remember

Repeatedly select the minimum of the unsorted part. Always O(n^2) comparisons, at most n - 1 swaps, not stable.
