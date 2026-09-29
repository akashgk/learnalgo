// Dijkstra's Algorithm: shortest distances from `start` in a directed graph with
// non-negative weights. edges[u] = [[v, weight], ...]. -1 for unreachable vertices.
// Binary heap with lazy deletion: O((v + e) log v) time, O(v + e) space.

List<int> dijkstrasAlgorithm(int start, List<List<List<int>>> edges) {
  const inf = 1 << 62;
  final dist = List<int>.filled(edges.length, inf)..[start] = 0;
  final heap = _MinHeap<(int, int)>((a, b) => a.$1.compareTo(b.$1))..push((0, start));
  while (heap.isNotEmpty) {
    final (d, u) = heap.pop();
    if (d > dist[u]) continue; // stale entry: u was already finalized with a shorter distance
    for (final [v, w] in edges[u]) {
      if (d + w < dist[v]) {
        dist[v] = d + w;
        heap.push((dist[v], v));
      }
    }
  }
  return [for (final d in dist) d == inf ? -1 : d];
}

/// Minimal binary heap (the Dart core SDK has no priority queue).
class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

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
  final edges = [
    [
      [1, 7],
    ],
    [
      [2, 6],
      [3, 20],
      [4, 3],
    ],
    [
      [3, 14],
    ],
    [
      [4, 2],
    ],
    <List<int>>[],
    <List<int>>[],
  ];
  check(dijkstrasAlgorithm(0, edges), [0, 7, 13, 27, 10, -1]);
  check(dijkstrasAlgorithm(0, [<List<int>>[]]), [0]);
}
