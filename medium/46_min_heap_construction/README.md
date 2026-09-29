# Min Heap Construction

**Difficulty:** Medium | **Category:** Heaps | **Pattern:** Array-backed binary heap

## The problem

Implement a `MinHeap` class backed by an array, with:

- `buildHeap(array)`: turn an arbitrary array into a valid min-heap;
- `insert(value)`;
- `remove()`: remove and return the minimum;
- `peek()`: return the minimum without removing it;
- `siftUp` and `siftDown` helpers.

## Step 1: What a heap is

A binary min-heap is a **complete binary tree** (every level full except possibly the last, which fills from the left) where **every parent is <= its children**. So the minimum is always at the root.

Because the tree is complete, it fits perfectly in an array with no pointers, level by level:

```
            1                  index: 0  1  2  3  4  5  6
          /   \                value: 1  3  2  7  4  5  6
         3     2
        / \   / \
       7   4 5   6
```

For the node at index `i`:
- left child `2i + 1`, right child `2i + 2`,
- parent `(i - 1) ~/ 2`.

Memorize these three formulas.

## Step 2: insert: sift up

1. Append the value at the end (keeps the tree complete).
2. While it is smaller than its parent, swap with the parent.

At most one swap per level: **O(log n)**.

## Step 3: remove: sift down

1. The minimum is at index 0. Swap it with the last element and pop the last (removing the minimum, keeping the tree complete).
2. The new root is probably too big. While it is bigger than one of its children, swap it with the **smaller** child.

Why the smaller child? After the swap, that child becomes the parent of the other child, so it must be the smaller of the two for the heap property to hold.

**O(log n)**.

## Step 4: buildHeap in O(n)

Naive: insert elements one by one, O(n log n).

Better: treat the array as a complete tree that violates the heap property, and fix it **bottom-up**: call sift-down on every non-leaf node, from the last parent `(n - 2) ~/ 2` back to the root. Leaves (half the nodes) need no work.

**Why O(n) and not O(n log n)?** Sift-down cost is proportional to a node's height, not its depth. About n/2 nodes are leaves (height 0), n/4 have height 1, n/8 height 2, and so on. Total work is `n/4 * 1 + n/8 * 2 + n/16 * 3 + ... <= n`. The many nodes near the bottom are cheap; only a few nodes near the top are expensive. Being able to explain this is a strong signal.

## Step 5: The code

<!-- CODE:START -->

Full source: [`min_heap_construction.dart`](min_heap_construction.dart) (run it with `dart run`).

```dart
// Min Heap Construction backed by a List.
// buildHeap O(n); insert/remove O(log n); peek O(1). O(1) extra space.

class MinHeap {
  MinHeap(List<int> array) : heap = buildHeap(array);
  final List<int> heap;

  /// Heapify in place: sift down every non-leaf from the bottom up. O(n) total.
  static List<int> buildHeap(List<int> array) {
    for (var i = (array.length - 2) ~/ 2; i >= 0; i--) {
      _siftDown(array, i, array.length - 1);
    }
    return array;
  }

  static void _siftDown(List<int> h, int idx, int endIdx) {
    var i = idx;
    while (true) {
      final l = 2 * i + 1, r = 2 * i + 2;
      var smallest = i;
      if (l <= endIdx && h[l] < h[smallest]) smallest = l;
      if (r <= endIdx && h[r] < h[smallest]) smallest = r;
      if (smallest == i) return;
      _swap(h, i, smallest);
      i = smallest;
    }
  }

  static void _siftUp(List<int> h, int idx) {
    var i = idx;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (h[parent] <= h[i]) return;
      _swap(h, i, parent);
      i = parent;
    }
  }

  static void _swap(List<int> h, int i, int j) {
    final t = h[i];
    h[i] = h[j];
    h[j] = t;
  }

  int get length => heap.length;
  bool get isEmpty => heap.isEmpty;
  int peek() => heap.first;

  int remove() {
    _swap(heap, 0, heap.length - 1);
    final min = heap.removeLast();
    _siftDown(heap, 0, heap.length - 1);
    return min;
  }

  void insert(int value) {
    heap.add(value);
    _siftUp(heap, heap.length - 1);
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `MinHeap(List<int> array) : heap = buildHeap(array);` heapifies the given list in place.
- `buildHeap`: loop from the last parent down to 0, calling `_siftDown`.
- `_siftDown(h, idx, endIdx)`: find the smallest of the node and its (existing) children; if the node is already smallest, stop; else swap and continue from the child's position.
- `_siftUp(h, idx)`: while the parent is bigger, swap upward.
- `remove()`: swap root with last, `removeLast()` (the old minimum), sift down the new root. `endIdx` is `heap.length - 1` after removal.
- `insert(value)`: `add` then sift up.

## Step 6: Dry run: remove() on the heap above

Heap `[1, 3, 2, 7, 4, 5, 6]`:

| step | array |
|---|---|
| swap root with last | [6, 3, 2, 7, 4, 5, 1] |
| pop last (returns 1) | [6, 3, 2, 7, 4, 5] |
| sift down 6: children 3, 2, smaller is 2 (index 2) | [2, 3, 6, 7, 4, 5] |
| sift down 6 at index 2: child 5 (index 5) | [2, 3, 5, 7, 4, 6] |
| index 5 has no children | done, min is 2 |

## Complexity

| Operation | Time |
|---|---|
| buildHeap | O(n) |
| insert | O(log n) |
| remove | O(log n) |
| peek | O(1) |

Space: O(1) extra (the heap lives in the given array).

## Common mistakes

- Swapping with the **larger** child in sift-down (breaks the heap).
- Off-by-one in the parent/child formulas (they differ for 1-based arrays: children `2i`, `2i + 1`, parent `i / 2`).
- buildHeap by sifting **up** from the start (O(n log n), and needs care to be correct).

## Where heaps show up

Top-k problems, Dijkstra (hard 26), Prim (hard 29), Laptop Rentals (hard 32), Continuous Median (hard 34), Sort K-Sorted Array (hard 33), Merge Sorted Arrays (very hard 23), Heap Sort (hard 49).

Dart's core library has no priority queue; `package:collection` provides `PriorityQueue`. Many files in this repo include a small heap class based on this one.

## What to remember

Array-backed complete tree: children at `2i + 1` and `2i + 2`. Insert = append + sift up. Remove = swap root with last + sift down (toward the smaller child). Build = sift down from the last parent to the root, O(n).
