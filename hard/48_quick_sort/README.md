# Quick Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Divide and conquer via partitioning

## The problem

Sort an integer array in ascending order using Quick Sort, in place.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: The idea

1. Pick a **pivot**.
2. **Partition:** rearrange the range so that everything smaller than the pivot is on its left and everything larger is on its right. The pivot is now at its final sorted position.
3. Recursively sort the left part and the right part.

Unlike merge sort, there is no merge step: all the work happens during partitioning.

## Step 2: The partition used here (two pointers)

Pivot = first element of the range. `left` starts just after it, `right` at the end.

- If `a[left] > pivot` **and** `a[right] < pivot`, both are on the wrong side: swap them.
- Advance `left` while `a[left] <= pivot`; retreat `right` while `a[right] >= pivot`.
- When the pointers cross, swap the pivot into position `right`. Everything left of `right` is `<= pivot`, everything right of it is `>= pivot`.

## Step 3: Keeping the stack small

Recursing on both parts can create O(n) recursion depth on bad inputs. The trick: **recurse into the smaller part and loop on the larger one** (manual tail-call elimination). The smaller part has at most half the elements, so the recursion depth is at most O(log n), even when pivots are bad. Mentioning this is a strong signal.

## Step 4: The code

<!-- CODE:START -->

Full source: [`quick_sort.dart`](quick_sort.dart) (run it with `dart run`).

```dart
// Quick Sort (in place). Hoare-style partition around the first element; recurse on the
// smaller side first so the stack depth stays O(log n).
// Average O(n log n), worst O(n^2) time. Not stable.

List<int> quickSort(List<int> array) {
  _sort(array, 0, array.length - 1);
  return array;
}

void _sort(List<int> a, int start, int end) {
  while (start < end) {
    final pivot = a[start];
    var left = start + 1, right = end;
    while (left <= right) {
      if (a[left] > pivot && a[right] < pivot) _swap(a, left, right);
      if (a[left] <= pivot) left++;
      if (a[right] >= pivot) right--;
    }
    _swap(a, start, right); // pivot lands at its final position `right`
    // Recurse into the smaller part, loop on the larger one (tail-call elimination by hand).
    if (right - start < end - right) {
      _sort(a, start, right - 1);
      start = right + 1;
    } else {
      _sort(a, right + 1, end);
      end = right - 1;
    }
  }
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}
```

<!-- CODE:END -->

### Walkthrough

- `_sort(a, start, end)` loops while the range has at least 2 elements.
- The inner `while (left <= right)` is the partition from Step 2.
- `_swap(a, start, right)` places the pivot.
- The final `if/else` recurses into the smaller side and updates `start` or `end` to continue with the larger side in the loop.

## Step 5: Result of the first partition

Starting from `[8, 5, 2, 9, 5, 6, 3]` with pivot 8, the pointers swap the out-of-place pair (9 and 3), then cross. The pivot is swapped into its final position:

```
before: [8, 5, 2, 9, 5, 6, 3]
after:  [6, 5, 2, 3, 5, 8, 9]     8 is now at index 5, its sorted position
```

The left part `[6, 5, 2, 3, 5]` and the right part `[9]` are then sorted the same way. (Run the code with a print inside the loop to watch every pointer move; tracing a partition by hand once is worth doing.)

## Complexity

| Case | Time | Why |
|---|---|---|
| Best / average | O(n log n) | pivots split the range roughly in half: log n levels of O(n) work |
| Worst | O(n^2) | pivot always the min or max (for example sorted input with a first-element pivot) |

- **Space: O(log n)** stack with the smaller-side trick.
- **Not stable.** In place.

## Making the worst case unlikely

- Random pivot, or median of three (first, middle, last).
- **Introsort** (C++ `std::sort`): switch to Heap Sort if recursion gets too deep, guaranteeing O(n log n).

## Why is quicksort fast in practice?

In place, sequential memory access (cache friendly), and small constant factors. That usually beats merge sort (extra memory) and heap sort (scattered access) despite the O(n^2) worst case.

## Common mistakes

- Infinite loops when many values equal the pivot (the `<=` / `>=` in the pointer moves handle it here).
- Recursing into both sides without the smaller-side trick (stack overflow on bad inputs).

## What to remember

Partition around a pivot, recurse on both sides (smaller side first to bound the stack). Average O(n log n), worst O(n^2), fixed by random pivots or introsort.
