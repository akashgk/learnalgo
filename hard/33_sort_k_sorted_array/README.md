# Sort K-Sorted Array

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Sliding window min-heap

## The problem

An array is **k-sorted**: every element is at most `k` positions away from its position in sorted order. Sort it (in place), faster than a general `O(n log n)` sort when k is small.

```
[3, 2, 1, 5, 4, 7, 6, 5], k = 3  ->  [1, 2, 3, 4, 5, 5, 6, 7]
```

## Step 1: Baselines

- General sort: O(n log n). Ignores k.
- **Insertion sort:** each element moves at most k positions left, so it is O(n * k). Good for very small k.

## Step 2: The key observation

Where can the smallest element be? Its sorted position is 0, and it is at most k positions away from there, so it is among the first **k + 1** elements.

After placing it, the second smallest belongs at position 1, so it is among positions `0 .. k + 1` of the original array, excluding the element already placed. In general, the element for output position `i` is among the input elements `i .. i + k` that have not been placed yet.

So a **sliding window of k + 1 candidates** always contains the next element of the sorted output, and that element is the window's minimum.

## Step 3: Min-heap of the window

1. Push elements into a min-heap as you read them.
2. Once the heap holds more than k elements (that is, k + 1), pop the minimum and write it to the next output position.
3. After reading everything, pop the remaining elements in order.

Writing into the same array is safe: the write position never overtakes the read position (it is always k behind).

## Step 4: The code

<!-- CODE:START -->

Full source: [`sort_k_sorted_array.dart`](sort_k_sorted_array.dart) (run it with `dart run`).

```dart
// Sort K-Sorted Array: every element is at most k positions from its sorted position.
// Sliding min-heap of size k + 1. O(n log k) time, O(k) space. Sorts in place.

List<int> sortKSortedArray(List<int> array, int k) {
  final heap = _MinHeap();
  var write = 0;
  for (final x in array) {
    heap.push(x);
    if (heap.length > k) array[write++] = heap.pop(); // the smallest of k+1 must go here
  }
  while (heap.length > 0) {
    array[write++] = heap.pop();
  }
  return array;
}

class _MinHeap {
  final _a = <int>[];
  int get length => _a.length;

  void push(int v) {
    _a.add(v);
    var i = _a.length - 1;
    while (i > 0 && _a[(i - 1) >> 1] > _a[i]) {
      _swap(i, (i - 1) >> 1);
      i = (i - 1) >> 1;
    }
  }

  int pop() {
    final top = _a.first, last = _a.removeLast();
    if (_a.isNotEmpty) {
      _a[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _a.length && _a[l] < _a[m]) m = l;
        if (r < _a.length && _a[r] < _a[m]) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _a[i];
    _a[i] = _a[j];
    _a[j] = t;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `heap` is a small binary min-heap of integers.
- For each `x`: push; if the heap now has more than `k` elements, pop the minimum into `array[write++]`.
- The final `while` drains the heap.

## Step 5: Dry run (k = 3)

| read | heap after push | pop | array prefix written |
|---|---|---|---|
| 3 | {3} | | |
| 2 | {2, 3} | | |
| 1 | {1, 2, 3} | | |
| 5 | {1, 2, 3, 5} | 1 | [1] |
| 4 | {2, 3, 4, 5} | 2 | [1, 2] |
| 7 | {3, 4, 5, 7} | 3 | [1, 2, 3] |
| 6 | {4, 5, 6, 7} | 4 | [1, 2, 3, 4] |
| 5 | {5, 5, 6, 7} | 5 | [1, 2, 3, 4, 5] |
| drain | | 5, 6, 7 | [1, 2, 3, 4, 5, 5, 6, 7] |

## Complexity

- **Time: O(n log k)**: n pushes and pops on a heap of size at most k + 1.
- **Space: O(k)**.

## Common mistakes

- A window of size k instead of k + 1.
- Popping before the window is full (outputs elements too early).

## Follow-ups

1. **Sort a Nearly Sorted Array** (common GeeksforGeeks / interview problem, identical).
2. **Merge k sorted lists (very hard 23):** another "heap of candidates" pattern.
3. **External sorting:** the same idea sorts streams where elements arrive only slightly out of order.

## What to remember

If every element is within k of its place, the next output is always the minimum of the next k + 1 candidates: keep them in a min-heap.
