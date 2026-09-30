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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    minInterval(
      [
        [1, 4],
        [2, 4],
        [3, 6],
        [4, 4],
      ],
      [2, 3, 4, 5],
    ),
    [3, 3, 1, 4],
  );
  check(
    minInterval(
      [
        [2, 3],
        [2, 5],
        [1, 8],
        [20, 25],
      ],
      [2, 19, 5, 22],
    ),
    [2, -1, 4, 6],
  );
}
