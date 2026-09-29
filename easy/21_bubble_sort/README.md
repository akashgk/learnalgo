# Bubble Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Adjacent swaps

## The problem

Sort an array of integers in ascending order using Bubble Sort, and return it.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: The idea

Walk through the array comparing each pair of neighbors. If a pair is out of order, swap it. After one full pass, the **largest** element has been carried all the way to the end, like a bubble rising to the surface. It is now in its final position.

Repeat the pass on the unsorted part. Each pass locks one more element at the end. When a pass makes no swaps at all, the array is sorted and you can stop.

## Step 2: Work an example by hand

First pass on `[8, 5, 2, 9, 5, 6, 3]`:

| compare | action | array |
|---|---|---|
| 8, 5 | swap | [5, 8, 2, 9, 5, 6, 3] |
| 8, 2 | swap | [5, 2, 8, 9, 5, 6, 3] |
| 8, 9 | ok | [5, 2, 8, 9, 5, 6, 3] |
| 9, 5 | swap | [5, 2, 8, 5, 9, 6, 3] |
| 9, 6 | swap | [5, 2, 8, 5, 6, 9, 3] |
| 9, 3 | swap | [5, 2, 8, 5, 6, 3, **9**] |

9 is now final. The second pass only needs to go up to index 5, the third up to index 4, and so on.

## Step 3: The code

<!-- CODE:START -->

Full source: [`bubble_sort.dart`](bubble_sort.dart) (run it with `dart run`).

```dart
// Bubble Sort (in place). Repeatedly swap adjacent out-of-order pairs; stop early when a
// pass makes no swaps. O(n^2) worst/avg, O(n) best (already sorted), O(1) space. Stable.

List<int> bubbleSort(List<int> array) {
  var sortedTail = 0;
  var swapped = true;
  while (swapped) {
    swapped = false;
    for (var i = 0; i < array.length - 1 - sortedTail; i++) {
      if (array[i] > array[i + 1]) {
        final tmp = array[i];
        array[i] = array[i + 1];
        array[i + 1] = tmp;
        swapped = true;
      }
    }
    sortedTail++; // the largest remaining element has bubbled to the end
  }
  return array;
}
```

<!-- CODE:END -->

### Walkthrough

- `var sortedTail = 0;` counts how many elements at the end are already final.
- `var swapped = true;` makes the loop run at least once. Each pass resets it to `false`.
- `for (var i = 0; i < array.length - 1 - sortedTail; i++)` compares neighbors `i` and `i + 1`, skipping the already-sorted tail.
- The swap uses a temporary variable. Dart record swap syntax like `(a[i], a[j]) = (a[j], a[i])` is **not** allowed for list elements (patterns can only assign to variables).
- `sortedTail++` after each pass: one more element is final.
- The `while (swapped)` loop ends after a pass with no swaps: the early-exit optimization.

## Complexity

| Case | Time | Why |
|---|---|---|
| Best (already sorted) | O(n) | one pass, no swaps, early exit |
| Average | O(n^2) | about n^2/4 swaps |
| Worst (reversed) | O(n^2) | n - 1 passes of decreasing length: n(n-1)/2 comparisons |

- **Space: O(1)**, in place.
- **Stable:** yes. Equal elements are never swapped (`>` not `>=`), so their relative order is kept.

## Common mistakes

- Using `>=` in the comparison: still sorts, but loses stability and does useless swaps.
- Looping to `array.length` instead of `array.length - 1`: reads past the end.
- Forgetting the early-exit flag, which makes the best case O(n^2).

## Why learn it at all?

You will not implement Bubble Sort in a real FAANG interview. You may be asked to **compare** sorting algorithms, and Bubble Sort is the baseline for concepts that matter:

- **stability** (defined above),
- **adaptive** behavior (faster on nearly sorted input thanks to early exit),
- **number of swaps** versus **number of comparisons**.

See the sorting table in the root README.

## What to remember

Each pass bubbles the largest remaining element to its final spot. O(n^2), stable, in place, O(n) best case with an early exit.
