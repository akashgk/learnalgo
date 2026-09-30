# Last Stone Weight

**Difficulty:** Easy | **Category:** Heap / Priority Queue | **Pattern:** Max-heap simulation | **Source:** LeetCode 1046; NeetCode 150

## The problem

Repeatedly take the two heaviest stones `y >= x` and smash them: if equal, both are destroyed; otherwise a stone of weight `y - x` remains. Return the weight of the last stone, or 0 if none are left.

```
[2, 7, 4, 1, 8, 1]  ->  1
8, 7 -> 1      [2, 4, 1, 1, 1]
4, 2 -> 2      [2, 1, 1, 1]
2, 1 -> 1      [1, 1, 1]
1, 1 -> 0      [1]
```

## Step 1: Brute force

Sort, take the two largest, insert the difference back in sorted position: O(n) per round, O(n^2) total.

## Step 2: The right data structure

Every round needs "remove the two largest, maybe insert one". That is exactly a **max-heap**: O(log n) per operation, O(n log n) total.

Dart has no built-in heap; the file uses a min-heap with a **reversed comparator** (`b.compareTo(a)`), which makes the largest value come out first. In Python the same trick is negating values.

## Step 3: The code

<!-- CODE:START -->

Full source: [`last_stone_weight.dart`](last_stone_weight.dart) (run it with `dart run`).

```dart
// Last Stone Weight: repeatedly smash the two heaviest stones x <= y; if x == y both vanish,
// otherwise a stone of weight y - x remains. Return the last weight (0 if none).
// Max-heap simulation (a min-heap with a reversed comparator). O(n log n) time, O(n) space.

int lastStoneWeight(List<int> stones) {
  final heap = _MinHeap<int>((a, b) => b.compareTo(a)); // reversed: largest on top
  stones.forEach(heap.push);
  while (heap.length > 1) {
    final y = heap.pop(), x = heap.pop(); // heaviest, second heaviest
    if (y != x) heap.push(y - x);
  }
  return heap.length == 1 ? heap.pop() : 0;
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

- `heap.pop()` twice: the first pop is the heaviest (`y`), the second is `x`.
- Only a nonzero difference is pushed back.
- The loop stops when at most one stone remains.

## Step 4: Dry run

Shown above in the problem statement.

## Complexity

- Time: **O(n log n)**: at most n - 1 rounds, each O(log n).
- Space: **O(n)**.

## Edge cases

- One stone: its weight.
- Two equal stones: 0.

## Common mistakes

- Using a min-heap without reversing the comparator.
- Pushing back a zero-weight stone (harmless for the answer, but wrong in spirit and adds work).

## Follow-ups you should be ready for

1. **Last Stone Weight II (LeetCode 1049).** You choose which stones to smash: the answer is the minimum difference between two subset sums, a knapsack DP (see more_problems 39 Partition Equal Subset Sum).
2. **Bucket-based O(n + W)** when weights are small: count stones per weight and simulate from the top.

## What to remember

"Repeatedly take the largest" is a max-heap. In languages with only a min-heap, reverse the comparator (or negate the values).
