# Heap Sort

**Difficulty:** Hard | **Category:** Sorting | **Pattern:** Build a max-heap, then extract repeatedly

## The problem

Sort an integer array in ascending order using Heap Sort, in place.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: Connection to Selection Sort

Selection Sort repeatedly finds the largest (or smallest) remaining element with an O(n) scan. A **max-heap** gives the largest element in O(1) and restores itself in O(log n). **Heap Sort is Selection Sort with a heap.** That drops the total from O(n^2) to O(n log n).

(Heap basics: see Min Heap Construction, medium 46. Here we need a **max**-heap: every parent >= its children.)

## Step 2: Phase 1: build a max-heap in place

Treat the array as a complete binary tree (children of index `i` are `2i + 1` and `2i + 2`). Sift down every non-leaf node, from the last parent `(n - 2) ~/ 2` back to the root. This takes **O(n)** (most nodes are near the bottom and move only a little).

## Step 3: Phase 2: extract the maximum repeatedly

The array is split into a heap region `[0, end]` and a sorted region `(end, n - 1]`.

1. Swap the root (the maximum of the heap) with the last element of the heap region. The maximum is now in its **final** sorted position.
2. Shrink the heap region by one.
3. Sift down the new root to restore the heap.

Repeat until the heap region has one element.

## Step 4: The code

<!-- CODE:START -->

Full source: [`heap_sort.dart`](heap_sort.dart) (run it with `dart run`).

```dart
// Heap Sort (in place). Build a max-heap in O(n), then repeatedly swap the max to the end
// and sift down. O(n log n) time in all cases, O(1) space. Not stable.

List<int> heapSort(List<int> array) {
  final n = array.length;
  for (var i = (n - 2) ~/ 2; i >= 0; i--) {
    _siftDown(array, i, n - 1);
  }
  for (var end = n - 1; end > 0; end--) {
    _swap(array, 0, end); // current max goes to its final position
    _siftDown(array, 0, end - 1);
  }
  return array;
}

void _siftDown(List<int> a, int i, int endIdx) {
  while (true) {
    final l = 2 * i + 1, r = l + 1;
    var largest = i;
    if (l <= endIdx && a[l] > a[largest]) largest = l;
    if (r <= endIdx && a[r] > a[largest]) largest = r;
    if (largest == i) return;
    _swap(a, i, largest);
    i = largest;
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

- The first loop is heapify (Phase 1).
- The second loop swaps the max to the end and sifts down within `[0, end - 1]`.
- `_siftDown` picks the **larger** child (max-heap) and stops when the node is at least as large as both children.

## Step 5: Dry run

After heapify, `[8, 5, 2, 9, 5, 6, 3]` becomes `[9, 8, 6, 5, 5, 2, 3]` (a valid max-heap).

| step | swap root with | heap region after sift-down | sorted region |
|---|---|---|---|
| 1 | 3 (index 6) | [8, 5, 6, 3, 5, 2] | [9] |
| 2 | 2 | [6, 5, 2, 3, 5] | [8, 9] |
| 3 | 5 | [5, 5, 2, 3] | [6, 8, 9] |
| ... | | | |
| end | | [2] | [3, 5, 5, 6, 8, 9] |

## Complexity

- **Time: O(n log n)** in **every** case: O(n) to build, then n extractions of O(log n).
- **Space: O(1)**: fully in place.
- **Not stable.**

## Heap Sort vs Quick Sort vs Merge Sort

| | Heap | Quick | Merge |
|---|---|---|---|
| Worst case | O(n log n) | O(n^2) | O(n log n) |
| Extra space | O(1) | O(log n) | O(n) |
| Stable | no | no | yes |
| Cache behavior | poor (jumps between parents and children) | good | good |

Heap Sort's guaranteed bound and O(1) space make it the fallback inside introsort, but its poor locality makes it slower than quicksort on average.

## Common mistakes

- Sifting down with the wrong end index (touching the already-sorted region).
- Using a min-heap and expecting ascending order in place (you would get descending order).

## What to remember

Build a max-heap in O(n), then repeatedly swap the max to the end and sift down. O(n log n) always, O(1) space, not stable.
