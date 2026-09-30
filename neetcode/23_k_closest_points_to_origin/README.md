# K Closest Points to Origin

**Difficulty:** Medium | **Category:** Heap / Priority Queue | **Pattern:** Size-k max-heap (or quickselect) | **Source:** LeetCode 973; NeetCode 150

## The problem

Return the `k` points closest to the origin `(0, 0)` by Euclidean distance, in any order. The answer is unique up to order.

```
points = [[1, 3], [-2, 2]], k = 1          ->  [[-2, 2]]   (distance^2 8 < 10)
points = [[3, 3], [5, -1], [-2, 4]], k = 2 ->  [[3, 3], [-2, 4]]
```

## Step 1: No square roots

Comparing `sqrt(a) < sqrt(b)` is the same as comparing `a < b` for non-negative values. Use the **squared** distance `x^2 + y^2`: exact integers, no floating point.

## Step 2: Options

1. **Sort by distance, take k:** O(n log n).
2. **Size-k max-heap:** keep the k closest seen so far. The heap top is the **farthest** of them. For each new point, push it; if the heap has k + 1 points, pop the farthest. O(n log k). Best when k is much smaller than n, or for a stream.
3. **Quickselect** on distances: O(n) average, O(n^2) worst; partitions the array in place so the first k are the closest (AlgoExpert hard 46).

Note the flip: to keep the k **smallest**, use a **max**-heap (to evict the largest). To keep the k **largest**, use a min-heap (neetcode 21).

## Step 3: The code

<!-- CODE:START -->

Full source: [`k_closest_points_to_origin.dart`](k_closest_points_to_origin.dart) (run it with `dart run`).

```dart
// K Closest Points to Origin: return the k points with the smallest Euclidean distance to (0, 0).
// Compare squared distances (no square root needed). Max-heap of size k: push each point, pop the
// farthest when the heap exceeds k. O(n log k) time, O(k) space.

List<List<int>> kClosest(List<List<int>> points, int k) {
  int dist(List<int> p) => p[0] * p[0] + p[1] * p[1];
  final heap = _MinHeap<List<int>>((a, b) => dist(b).compareTo(dist(a))); // farthest on top
  for (final p in points) {
    heap.push(p);
    if (heap.length > k) heap.pop(); // the farthest of k + 1 points cannot be in the answer
  }
  final result = <List<int>>[];
  while (heap.length > 0) {
    result.add(heap.pop());
  }
  return result.reversed.toList(); // closest first, for readable output
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  int get length => _items.length;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[parent], _items[i]) <= 0) break;
      _swap(i, parent);
      i = parent;
    }
  }

  T pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _compare(_items[l], _items[m]) < 0) m = l;
        if (r < _items.length && _compare(_items[r], _items[m]) < 0) m = r;
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

- `dist(b).compareTo(dist(a))` reverses the order, so the heap top is the farthest point.
- After the loop, the heap holds exactly the k closest. Popping yields farthest first; the result is reversed only for a readable order.

## Step 4: Dry run

`[[3, 3], [5, -1], [-2, 4]]`, k = 2. Squared distances: 18, 26, 20.

| point | dist^2 | heap after push | popped | heap |
|---|---|---|---|---|
| (3, 3) | 18 | {18} | | {18} |
| (5, -1) | 26 | {26, 18} | | {26, 18} |
| (-2, 4) | 20 | {26, 20, 18} | 26 | {20, 18} |

Result: `[[3, 3], [-2, 4]]`.

## Complexity

| Approach | Time | Space |
|---|---|---|
| Sort | O(n log n) | O(n) |
| Size-k max-heap | O(n log k) | O(k) |
| Quickselect | O(n) average | O(1) extra (in place) |

## Edge cases

- `k == n`: all points.
- Ties in distance: any of the tied points is acceptable when the problem says the answer is unique; otherwise clarify.

## Common mistakes

- Using a min-heap of all points and popping k times (O(n + k log n), fine, but not the size-k answer interviewers look for).
- Using `sqrt` and comparing doubles.

## Follow-ups you should be ready for

1. **Stream of points.** The size-k heap handles it directly.
2. **Distance to a point other than the origin.** Same code with shifted coordinates.
3. **Top K Frequent Elements.** Same heap idea on frequencies; see more_problems 09.

## What to remember

To keep the k smallest, use a max-heap of size k and evict its top. Compare squared distances.
