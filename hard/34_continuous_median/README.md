# Continuous Median

**Difficulty:** Hard | **Category:** Heaps | **Pattern:** Two heaps (lower half max-heap, upper half min-heap)

## The problem

Implement a class that receives integers one at a time through `insert(number)`, and can return the **median** of all numbers inserted so far in **O(1)** at any time. For an even count, the median is the average of the two middle values.

```
insert 5    -> median 5
insert 10   -> median 7.5
insert 100  -> median 10
insert 200  -> median 55
insert 6    -> median 10
insert 13   -> median 11.5
insert 14   -> median 13
```

## Step 1: Baselines

- Keep a sorted list: median is O(1) (look at the middle), but insertion is O(n) because elements must shift.
- Re-sort on every query: O(n log n) per query.

## Step 2: What does the median depend on?

Only on the **boundary** between the smaller half and the larger half of the numbers. We never need the full order inside each half, only:

- the **largest** number of the lower half, and
- the **smallest** number of the upper half.

"Largest of a changing set" is a **max-heap**; "smallest of a changing set" is a **min-heap**.

## Step 3: Two heaps

- `lower`: max-heap holding the smaller half.
- `upper`: min-heap holding the larger half.

**Invariants:**

1. every number in `lower` <= every number in `upper`;
2. their sizes differ by at most 1.

**Insert:** if the number is smaller than `lower`'s top (or `lower` is empty), push it into `lower`; otherwise into `upper`. Then **rebalance**: if one heap has 2 more elements than the other, move its top to the other heap. Moving the top preserves invariant 1.

**Median:** if the sizes are equal, the average of both tops; otherwise the top of the larger heap.

## Step 4: The code

<!-- CODE:START -->

Full source: [`continuous_median.dart`](continuous_median.dart) (run it with `dart run`).

```dart
// Continuous Median: insert numbers one at a time; median available in O(1).
// Max-heap for the lower half, min-heap for the upper half, sizes differ by at most 1.
// insert O(log n), median O(1), O(n) space.

class ContinuousMedianHandler {
  final _lower = _Heap((a, b) => a > b); // max-heap
  final _upper = _Heap((a, b) => a < b); // min-heap
  double? median;

  void insert(int number) {
    if (_lower.isEmpty || number < _lower.peek()) {
      _lower.push(number);
    } else {
      _upper.push(number);
    }
    // Rebalance so neither half has more than one extra element.
    if (_lower.length > _upper.length + 1) _upper.push(_lower.pop());
    if (_upper.length > _lower.length + 1) _lower.push(_upper.pop());

    if (_lower.length == _upper.length) {
      median = (_lower.peek() + _upper.peek()) / 2;
    } else {
      median = (_lower.length > _upper.length ? _lower.peek() : _upper.peek()).toDouble();
    }
  }

  double? getMedian() => median;
}

/// Binary heap ordered by [_before] (returns true if a should be above b).
class _Heap {
  _Heap(this._before);
  final bool Function(int a, int b) _before;
  final _a = <int>[];

  int get length => _a.length;
  bool get isEmpty => _a.isEmpty;
  int peek() => _a.first;

  void push(int v) {
    _a.add(v);
    var i = _a.length - 1;
    while (i > 0 && _before(_a[i], _a[(i - 1) >> 1])) {
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
        if (l < _a.length && _before(_a[l], _a[m])) m = l;
        if (r < _a.length && _before(_a[r], _a[m])) m = r;
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

- `_Heap` is a binary heap parameterized by a comparison: `(a, b) => a > b` makes a max-heap, `(a, b) => a < b` a min-heap.
- `insert` chooses the side, rebalances, and recomputes `median` (stored so `getMedian` is O(1)).
- Division by 2 produces a `double`; single-top medians are converted with `toDouble()`.

## Step 5: Dry run

| insert | lower (max-heap) | upper (min-heap) | median |
|---|---|---|---|
| 5 | {5} | {} | 5 |
| 10 | {5} | {10} | 7.5 |
| 100 | {5} | {10, 100} | 10 (top of upper) |
| 200 | {5, 10} after rebalance | {100, 200} | (10 + 100) / 2 = 55 |
| 6 | {5, 6, 10} | {100, 200} | 10 |
| 13 | {5, 6, 10} | {13, 100, 200} | (10 + 13) / 2 = 11.5 |
| 14 | {5, 6, 10} | {13, 14, 100, 200} | 13 (top of the larger heap) |

(For 200: it goes to `upper`, making `upper` 3 vs `lower` 1, so `upper`'s top 10 moves to `lower`. For 14: sizes 3 vs 4 differ by only 1, so no rebalance is needed.)

## Complexity

- **insert: O(log n)**.
- **getMedian: O(1)**.
- **Space: O(n)**.

## Common mistakes

- Rebalancing when sizes differ by exactly 1 (allowed).
- Putting a new number in the wrong heap without comparing to the boundary, which breaks invariant 1.

## Follow-ups

1. **Find Median from Data Stream (LeetCode #295):** identical.
2. **Sliding Window Median (#480):** numbers also **leave**; use lazy deletion (a map of pending removals checked when tops are popped) or a balanced ordered multiset.
3. **Numbers in a small range (0..100):** keep 101 counters and walk them: O(1) insert, O(100) median.

## What to remember

The median lives at the boundary between two halves: a max-heap for the lower half and a min-heap for the upper half, kept balanced within one element.
