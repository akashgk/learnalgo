// Merge Sorted Arrays (k-way merge) with a min-heap of (value, arrayIdx, elementIdx).
// O(N log k) time, O(N + k) space (N total elements, k arrays).

List<int> mergeSortedArrays(List<List<int>> arrays) {
  final heap = _MinHeap();
  for (var a = 0; a < arrays.length; a++) {
    if (arrays[a].isNotEmpty) heap.push((arrays[a][0], a, 0));
  }
  final out = <int>[];
  while (heap.isNotEmpty) {
    final (value, a, i) = heap.pop();
    out.add(value);
    if (i + 1 < arrays[a].length) heap.push((arrays[a][i + 1], a, i + 1));
  }
  return out;
}

class _MinHeap {
  final _items = <(int, int, int)>[];
  bool get isNotEmpty => _items.isNotEmpty;

  void push((int, int, int) item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0 && _items[(i - 1) >> 1].$1 > _items[i].$1) {
      _swap(i, (i - 1) >> 1);
      i = (i - 1) >> 1;
    }
  }

  (int, int, int) pop() {
    final top = _items.first, last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _items[l].$1 < _items[m].$1) m = l;
        if (r < _items.length && _items[r].$1 < _items[m].$1) m = r;
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
    mergeSortedArrays([
      [1, 5, 9, 21],
      [-1, 0],
      [-124, 81, 121],
      [3, 6, 12, 20, 150],
    ]),
    [-124, -1, 0, 1, 3, 5, 6, 9, 12, 20, 21, 81, 121, 150],
  );
  check(mergeSortedArrays([[], [1], []]), [1]);
}
