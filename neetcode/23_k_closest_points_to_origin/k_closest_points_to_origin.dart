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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    kClosest([
      [1, 3],
      [-2, 2],
    ], 1),
    [
      [-2, 2],
    ],
  ); // 8 < 10
  check(
    kClosest([
      [3, 3],
      [5, -1],
      [-2, 4],
    ], 2),
    [
      [3, 3],
      [-2, 4],
    ],
  ); // 18, 20 (26 is dropped)
  check(
    kClosest([
      [0, 1],
      [1, 0],
    ], 2).length,
    2,
  );
}
