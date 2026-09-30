// Kth Largest Element in a Stream: after each add(val), return the k-th largest value so far.
// Keep a min-heap of the k largest values; its top is the k-th largest.
// add is O(log k), space O(k).

class KthLargest {
  KthLargest(this.k, List<int> nums) {
    nums.forEach(add);
  }

  final int k;
  final _heap = _MinHeap<int>((a, b) => a.compareTo(b));

  int add(int val) {
    _heap.push(val);
    if (_heap.length > k) _heap.pop(); // drop the smallest: it can never be the k-th largest again
    return _heap.peek; // the smallest of the k largest
  }
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  int get length => _items.length;
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
  final kth = KthLargest(3, [4, 5, 8, 2]);
  check(kth.add(3), 4);
  check(kth.add(5), 5);
  check(kth.add(10), 5);
  check(kth.add(9), 8);
  check(kth.add(4), 8);
  final one = KthLargest(1, []);
  check(one.add(-3), -3);
  check(one.add(-2), -2);
}
