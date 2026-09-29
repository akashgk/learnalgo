// Prim's Algorithm: MST grown from vertex 0 using a min-heap of crossing edges.
// Input/output: edges[u] = [[v, w], ...] (undirected, both directions listed).
// O(e log e) time, O(v + e) space. Assumes a connected graph.

List<List<List<int>>> primsAlgorithm(List<List<List<int>>> edges) {
  final inTree = List<bool>.filled(edges.length, false);
  final mst = List.generate(edges.length, (_) => <List<int>>[]);
  if (edges.isEmpty) return mst;
  final heap = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (w, from, to)

  void addVertex(int u) {
    inTree[u] = true;
    for (final [v, w] in edges[u]) {
      if (!inTree[v]) heap.push((w, u, v));
    }
  }

  addVertex(0);
  while (heap.isNotEmpty) {
    final (w, u, v) = heap.pop();
    if (inTree[v]) continue; // both ends already in the tree
    mst[u].add([v, w]);
    mst[v].add([u, w]);
    addVertex(v);
  }
  return mst;
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_compare(_items[p], _items[i]) <= 0) break;
      _swap(i, p);
      i = p;
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
  final graph = [
    [[1, 3], [2, 5]],
    [[0, 3], [2, 10], [3, 12]],
    [[0, 5], [1, 10]],
    [[1, 12]],
  ];
  check(primsAlgorithm(graph), [[[1, 3], [2, 5]], [[0, 3], [3, 12]], [[0, 5]], [[1, 12]]]);
}
