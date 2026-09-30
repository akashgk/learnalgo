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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(lastStoneWeight([2, 7, 4, 1, 8, 1]), 1);
  check(lastStoneWeight([1]), 1);
  check(lastStoneWeight([3, 3]), 0);
  check(lastStoneWeight([10, 4, 2, 10]), 2);
}
