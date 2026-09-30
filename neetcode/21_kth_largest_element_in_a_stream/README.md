# Kth Largest Element in a Stream

**Difficulty:** Easy | **Category:** Heap / Priority Queue | **Pattern:** Size-k min-heap | **Source:** LeetCode 703; NeetCode 150

## The problem

Design a class that is given `k` and an initial list, and supports `add(val)`, returning the **k-th largest** value seen so far after each add.

```
KthLargest(3, [4, 5, 8, 2])
add(3)  -> 4     values 2 3 4 5 8: third largest is 4
add(5)  -> 5
add(10) -> 5
add(9)  -> 8
add(4)  -> 8
```

## Step 1: Brute force

Keep all values sorted; insert with binary search (O(n) shifting), read index `n - k`. O(n) per add.

## Step 2: Which values matter?

Only the **k largest** values can ever be the answer. Once a value is smaller than k other values, new values only push it further down: it will never be the k-th largest again. So keep just the top k.

Among the top k, the answer is the **smallest** one. A **min-heap** of size k gives it at the top.

On `add(val)`:

1. push `val`;
2. if the heap has more than k values, pop the smallest (it just dropped out of the top k);
3. the top is the answer.

## Step 3: The code

<!-- CODE:START -->

Full source: [`kth_largest_element_in_a_stream.dart`](kth_largest_element_in_a_stream.dart) (run it with `dart run`).

```dart
// Kth Largest Element in a Stream: after each add(val), return the k-th largest value so far.
// Keep a min-heap of the k largest values; its top is the k-th largest.
// add is O(log k), space O(k).

class KthLargest {
  KthLargest(this.k, List<int> nums) {
    nums.forEach(add);
  }

  final int k;
  final _heap = _MinHeap<int>((a, b) => a.compareTo(b));

  int add(int val) {
    _heap.push(val);
    if (_heap.length > k) _heap.pop(); // drop the smallest: it can never be the k-th largest again
    return _heap.peek; // the smallest of the k largest
  }
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  int get length => _items.length;
  T get peek => _items.first;

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

- The constructor simply adds the initial values one by one.
- `_MinHeap` is a small binary heap (Dart's core library has no priority queue; `package:collection` has `PriorityQueue`).
- `peek` reads the top without removing it.

## Step 4: Dry run

k = 3. Initial values 4, 5, 8, 2 leave the heap as {4, 5, 8} (2 was popped).

| add | heap after push | popped | heap | answer |
|---|---|---|---|---|
| 3 | {3, 4, 5, 8} | 3 | {4, 5, 8} | 4 |
| 5 | {4, 5, 5, 8} | 4 | {5, 5, 8} | 5 |
| 10 | {5, 5, 8, 10} | 5 | {5, 8, 10} | 5 |
| 9 | {5, 8, 9, 10} | 5 | {8, 9, 10} | 8 |
| 4 | {4, 8, 9, 10} | 4 | {8, 9, 10} | 8 |

## Complexity

- `add`: **O(log k)**.
- Construction: **O(n log k)**.
- Space: **O(k)**.

## Edge cases

- Fewer than k values initially: LeetCode guarantees at least k values exist whenever the answer is read (the initial list has at least k - 1 values and every `add` adds one).
- Duplicates: kept, since the k-th largest counts duplicates.

## Common mistakes

- A **max**-heap of everything (O(n) memory, O(k log n) per query).
- Popping before pushing, which drops the new value's chance to enter.

## Follow-ups you should be ready for

1. **Kth largest in a static array (LeetCode 215).** Quickselect, O(n) average; see AlgoExpert hard 46.
2. **Median of a stream.** Two heaps; see AlgoExpert hard 34 Continuous Median.
3. **Sliding window version.** Needs deletions: a balanced BST or two heaps with lazy deletion.

## What to remember

"k-th largest so far" = min-heap holding the k largest; the top is the answer.
