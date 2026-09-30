// Swim in Rising Water: grid[r][c] is an elevation (a permutation of 0..n*n-1). At time t you can
// swim between adjacent cells whose elevations are both <= t. Minimum t to get from the top-left
// to the bottom-right: minimize the MAXIMUM elevation along a path.
// Dijkstra variant: a path's cost is its max cell, expanded in increasing cost with a min-heap.
// O(n^2 log n) time, O(n^2) space.

int swimInWater(List<List<int>> grid) {
  final n = grid.length;
  final visited = List.generate(n, (_) => List<bool>.filled(n, false));
  final heap = _MinHeap<(int, int, int)>((a, b) => a.$1.compareTo(b.$1)); // (time, r, c)
  heap.push((grid[0][0], 0, 0));
  while (true) {
    final (t, r, c) = heap.pop(); // smallest possible "highest cell so far" among the frontier
    if (visited[r][c]) continue;
    visited[r][c] = true;
    if (r == n - 1 && c == n - 1) return t;
    for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr < 0 || nc < 0 || nr >= n || nc >= n || visited[nr][nc]) continue;
      final next = grid[nr][nc] > t ? grid[nr][nc] : t; // the path's max so far
      heap.push((next, nr, nc));
    }
  }
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

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
    swimInWater([
      [0, 2],
      [1, 3],
    ]),
    3,
  );
  check(
    swimInWater([
      [0, 1, 2, 3, 4],
      [24, 23, 22, 21, 5],
      [12, 13, 14, 15, 16],
      [11, 17, 18, 19, 20],
      [10, 9, 8, 7, 6],
    ]),
    16,
  );
  check(
    swimInWater([
      [0],
    ]),
    0,
  );
  check(
    swimInWater([
      [3, 2],
      [0, 1],
    ]),
    3,
  ); // the start cell itself is high
}
