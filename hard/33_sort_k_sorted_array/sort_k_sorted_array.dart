// Sort K-Sorted Array: every element is at most k positions from its sorted position.
// Sliding min-heap of size k + 1. O(n log k) time, O(k) space. Sorts in place.

List<int> sortKSortedArray(List<int> array, int k) {
  final heap = _MinHeap();
  var write = 0;
  for (final x in array) {
    heap.push(x);
    if (heap.length > k) array[write++] = heap.pop(); // the smallest of k+1 must go here
  }
  while (heap.length > 0) {
    array[write++] = heap.pop();
  }
  return array;
}

class _MinHeap {
  final _a = <int>[];
  int get length => _a.length;

  void push(int v) {
    _a.add(v);
    var i = _a.length - 1;
    while (i > 0 && _a[(i - 1) >> 1] > _a[i]) {
      _swap(i, (i - 1) >> 1);
      i = (i - 1) >> 1;
    }
  }

  int pop() {
    final top = _a.first, last = _a.removeLast();
    if (_a.isNotEmpty) {
      _a[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _a.length && _a[l] < _a[m]) m = l;
        if (r < _a.length && _a[r] < _a[m]) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _a[i];
    _a[i] = _a[j];
    _a[j] = t;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sortKSortedArray([3, 2, 1, 5, 4, 7, 6, 5], 3), [1, 2, 3, 4, 5, 5, 6, 7]);
  check(sortKSortedArray([], 2), []);
  check(sortKSortedArray([1, 2, 3], 0), [1, 2, 3]);
}
