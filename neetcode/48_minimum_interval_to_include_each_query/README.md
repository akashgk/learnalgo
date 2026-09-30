# Minimum Interval to Include Each Query

**Difficulty:** Hard | **Category:** Intervals | **Pattern:** Offline sweep: sort queries, min-heap with lazy removal | **Source:** LeetCode 1851; NeetCode 150

## The problem

Each interval `[left, right]` has size `right - left + 1`. For each query `q`, return the size of the **smallest** interval with `left <= q <= right`, or -1 if none. Answer in the original query order.

```
intervals = [[1,4], [2,4], [3,6], [4,4]], queries = [2, 3, 4, 5]  ->  [3, 3, 1, 4]
```

Query 2: `[1,4]` (4) and `[2,4]` (3) contain it: 3. Query 4: `[4,4]` has size 1.

## Step 1: Brute force

For each query, scan all intervals: O(n * q). With 10^5 of each, too slow.

## Step 2: Answer the queries in sorted order (offline)

We are allowed to answer in any order internally and put answers back in their original positions. Sort the queries ascending and sweep:

- **Intervals become candidates** when `left <= q`. Since queries only increase, once an interval has started it stays started: add intervals in order of `left`, each exactly once.
- **Intervals stop being candidates** when `right < q`. Since queries only increase, once an interval has ended it never helps again: it can be discarded forever.

Among the current candidates, we want the smallest **size**: a **min-heap** keyed by size.

## Step 3: Lazy removal

Removing ended intervals from the middle of a heap is expensive. Instead, only remove them when they reach the **top**: before answering, pop while the top's `right < q`. Any ended interval still buried in the heap does not matter until it becomes the top, and at that point it is removed. Each interval is pushed once and popped at most once.

## Step 4: The code

<!-- CODE:START -->

Full source: [`minimum_interval_to_include_each_query.dart`](minimum_interval_to_include_each_query.dart) (run it with `dart run`).

```dart
// Minimum Interval to Include Each Query: for each query q, the size (right - left + 1) of the
// smallest interval with left <= q <= right, or -1.
// Offline sweep: sort intervals by left and queries by value. For each query in increasing order,
// push every interval that has started, keyed by size, then pop intervals that already ended.
// O((n + q) log n + q log q) time, O(n + q) space.

List<int> minInterval(List<List<int>> intervals, List<int> queries) {
  final sorted = [...intervals]..sort((a, b) => a[0].compareTo(b[0]));
  final order = List<int>.generate(queries.length, (i) => i)..sort((a, b) => queries[a].compareTo(queries[b]));
  final heap = _MinHeap<(int, int)>((a, b) => a.$1.compareTo(b.$1)); // (size, right end)
  final answer = List<int>.filled(queries.length, -1);
  var i = 0;
  for (final qi in order) {
    final q = queries[qi];
    // Every interval that starts at or before q is a candidate from now on (queries only grow).
    while (i < sorted.length && sorted[i][0] <= q) {
      heap.push((sorted[i][1] - sorted[i][0] + 1, sorted[i][1]));
      i++;
    }
    // Intervals that end before q can never contain this or any later query: discard them lazily.
    while (heap.isNotEmpty && heap.peek.$2 < q) {
      heap.pop();
    }
    if (heap.isNotEmpty) answer[qi] = heap.peek.$1;
  }
  return answer;
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;
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

- `sorted` is the intervals by left; `order` is query indices sorted by value (so answers go back to `answer[qi]`).
- The first `while` pushes every interval that has started.
- The second `while` pops expired intervals from the top.
- The heap stores `(size, right)` records; only `right` is needed for expiry.

## Step 5: Dry run

Intervals by left: `[1,4]` (size 4), `[2,4]` (3), `[3,6]` (4), `[4,4]` (1).

| query | pushed | popped (expired) | top | answer |
|---|---|---|---|---|
| 2 | [1,4], [2,4] | | size 3 | 3 |
| 3 | [3,6] | | size 3 ([2,4]) | 3 |
| 4 | [4,4] | | size 1 | 1 |
| 5 | | [4,4] then [2,4] (right < 5); [1,4] too if it surfaces before [3,6] (both have size 4) | size 4 ([3,6]) | 4 |

## Complexity

- Time: **O(n log n + q log q)**: sorting both, plus each interval pushed and popped once.
- Space: **O(n + q)**.

## Edge cases

- No interval contains a query: -1.
- Duplicate queries: each gets its own answer (the sweep handles them in sequence).
- Single-point intervals `[x, x]`: size 1.

## Common mistakes

- Answering in sorted order and forgetting to map back to the original order.
- Removing expired intervals eagerly (needs a heap with deletion).
- Checking expiry with `<=` (an interval with `right == q` still contains q).

## Follow-ups you should be ready for

1. **Online queries.** A segment tree over coordinates storing the minimum size covering each point (after coordinate compression).
2. **Count intervals containing each query.** Sort starts and ends separately; binary search.
3. **Meeting Rooms II / Laptop Rentals.** The same "sort + heap of ends" sweep.

## What to remember

When queries can be answered in any order, sort them and sweep. Add candidates as they become valid, and remove expired ones lazily from the heap top.
