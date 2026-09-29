# Merge Sorted Arrays

**Difficulty:** Very Hard | **Category:** Heaps | **Pattern:** K-way merge with a min-heap

## The problem

Given k arrays of integers, each sorted in ascending order, return one sorted array containing all their elements.

```
[[1, 5, 9, 21], [-1, 0], [-124, 81, 121], [3, 6, 12, 20, 150]]
->  [-124, -1, 0, 1, 3, 5, 6, 9, 12, 20, 21, 81, 121, 150]
```

Let N be the total number of elements.

## Step 1: Baselines

- Concatenate and sort: **O(N log N)**. Ignores that the inputs are sorted.
- **Scan the fronts:** the next output element is the smallest among the k current front elements. Finding it by scanning all k fronts costs O(k) per output element: **O(N * k)**.

## Step 2: Min-heap of the fronts

Put one entry per array into a **min-heap**: `(value, arrayIndex, elementIndex)`.

1. Pop the smallest entry and append its value to the output.
2. Push the **next** element from the same array (if any).
3. Repeat until the heap is empty.

The heap never holds more than k entries, so each operation is O(log k): **O(N log k)** total.

## Step 3: Alternative: divide and conquer

Merge the arrays in pairs (array 0 with 1, 2 with 3, ...), then merge the results in pairs, and so on. There are log k rounds, and each round touches all N elements: also **O(N log k)**, with no heap. This is the upper half of merge sort.

## Step 4: The code

<!-- CODE:START -->

Full source: [`merge_sorted_arrays.dart`](merge_sorted_arrays.dart) (run it with `dart run`).

```dart
// Merge Sorted Arrays (k-way merge) with a min-heap of (value, arrayIdx, elementIdx).
// O(N log k) time, O(N + k) space (N total elements, k arrays).

List<int> mergeSortedArrays(List<List<int>> arrays) {
  final heap = _MinHeap();
  for (var a = 0; a < arrays.length; a++) {
    if (arrays[a].isNotEmpty) heap.push((arrays[a][0], a, 0));
  }
  final out = <int>[];
  while (heap.isNotEmpty) {
    final (value, a, i) = heap.pop();
    out.add(value);
    if (i + 1 < arrays[a].length) heap.push((arrays[a][i + 1], a, i + 1));
  }
  return out;
}

class _MinHeap {
  final _items = <(int, int, int)>[];
  bool get isNotEmpty => _items.isNotEmpty;

  void push((int, int, int) item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0 && _items[(i - 1) >> 1].$1 > _items[i].$1) {
      _swap(i, (i - 1) >> 1);
      i = (i - 1) >> 1;
    }
  }

  (int, int, int) pop() {
    final top = _items.first, last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _items[l].$1 < _items[m].$1) m = l;
        if (r < _items.length && _items[r].$1 < _items[m].$1) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop pushes the first element of every non-empty array.
- The main loop pops the minimum, records it, and pushes that array's next element.
- `_MinHeap` compares records by their first field (the value).

## Step 5: Dry run (first steps)

| heap (value from array) | pop | push |
|---|---|---|
| 1(a0), -1(a1), -124(a2), 3(a3) | -124 | 81 (a2) |
| 1, -1, 81, 3 | -1 | 0 (a1) |
| 1, 0, 81, 3 | 0 | (a1 is empty) |
| 1, 81, 3 | 1 | 5 (a0) |
| 5, 81, 3 | 3 | 6 (a3) |
| ... | ... | ... |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Concatenate + sort | O(N log N) | O(N) |
| Scan fronts | O(N * k) | O(N + k) |
| Min-heap | O(N log k) | O(N + k) |
| Pairwise merging | O(N log k) | O(N) |

## Common mistakes

- Pushing all elements at once (that is just heap sort: O(N log N)).
- Forgetting empty input arrays.

## Follow-ups

1. **Merge k Sorted Lists (LeetCode #23):** the same with linked lists.
2. **Smallest Range Covering Elements from K Lists (#632):** a heap of fronts plus tracking the current maximum.
3. **External sorting:** sort chunks that fit in memory, write them to disk, then k-way merge the sorted chunks. This connects the interview question to how databases sort huge tables.

## What to remember

To merge k sorted sequences, keep only their current fronts in a min-heap: each output element costs O(log k).
