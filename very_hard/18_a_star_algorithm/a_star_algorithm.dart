// A* Algorithm on a grid (0 = free, 1 = obstacle), 4-directional moves of cost 1.
// Priority = g (cost so far) + h (Manhattan distance, admissible and consistent).
// Returns the path as [[row, col], ...], or [] if unreachable. O(wh log(wh)) time, O(wh) space.

List<List<int>> aStarAlgorithm(int startRow, int startCol, int endRow, int endCol, List<List<int>> graph) {
  final rows = graph.length, cols = graph[0].length;
  int h(int r, int c) => (r - endRow).abs() + (c - endCol).abs();
  const inf = 1 << 30;
  final g = List.generate(rows, (_) => List<int>.filled(cols, inf));
  final cameFrom = <(int, int), (int, int)>{};
  final open = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (f, r, c)
  g[startRow][startCol] = 0;
  open.push((h(startRow, startCol), startRow, startCol));
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  while (open.isNotEmpty) {
    final (f, r, c) = open.pop();
    if (f - h(r, c) > g[r][c]) continue; // stale heap entry
    if (r == endRow && c == endCol) {
      final path = <List<int>>[];
      (int, int)? node = (r, c);
      while (node != null) {
        path.add([node.$1, node.$2]);
        node = cameFrom[node];
      }
      return path.reversed.toList();
    }
    for (final (dr, dc) in dirs) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols || graph[nr][nc] == 1) continue;
      final tentative = g[r][c] + 1;
      if (tentative < g[nr][nc]) {
        g[nr][nc] = tentative;
        cameFrom[(nr, nc)] = (r, c);
        open.push((tentative + h(nr, nc), nr, nc));
      }
    }
  }
  return [];
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
    final top = _items.first, last = _items.removeLast();
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
    [0, 0, 0, 0, 0],
    [0, 1, 1, 1, 0],
    [0, 0, 0, 0, 0],
    [1, 0, 1, 1, 1],
    [0, 0, 0, 0, 0],
  ];
  final path = aStarAlgorithm(0, 1, 4, 3, graph);
  check(path.length, 9); // shortest path has 8 moves
  check(path.first, [0, 1]);
  check(path.last, [4, 3]);
  check(aStarAlgorithm(0, 0, 1, 1, [[0, 1], [1, 0]]), []);
}
