// Continuous Median: insert numbers one at a time; median available in O(1).
// Max-heap for the lower half, min-heap for the upper half, sizes differ by at most 1.
// insert O(log n), median O(1), O(n) space.

class ContinuousMedianHandler {
  final _lower = _Heap((a, b) => a > b); // max-heap
  final _upper = _Heap((a, b) => a < b); // min-heap
  double? median;

  void insert(int number) {
    if (_lower.isEmpty || number < _lower.peek()) {
      _lower.push(number);
    } else {
      _upper.push(number);
    }
    // Rebalance so neither half has more than one extra element.
    if (_lower.length > _upper.length + 1) _upper.push(_lower.pop());
    if (_upper.length > _lower.length + 1) _lower.push(_upper.pop());

    if (_lower.length == _upper.length) {
      median = (_lower.peek() + _upper.peek()) / 2;
    } else {
      median = (_lower.length > _upper.length ? _lower.peek() : _upper.peek()).toDouble();
    }
  }

  double? getMedian() => median;
}

/// Binary heap ordered by [_before] (returns true if a should be above b).
class _Heap {
  _Heap(this._before);
  final bool Function(int a, int b) _before;
  final _a = <int>[];

  int get length => _a.length;
  bool get isEmpty => _a.isEmpty;
  int peek() => _a.first;

  void push(int v) {
    _a.add(v);
    var i = _a.length - 1;
    while (i > 0 && _before(_a[i], _a[(i - 1) >> 1])) {
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
        if (l < _a.length && _before(_a[l], _a[m])) m = l;
        if (r < _a.length && _before(_a[r], _a[m])) m = r;
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
  final h = ContinuousMedianHandler();
  final medians = <double?>[];
  for (final x in [5, 10, 100, 200, 6, 13, 14]) {
    h.insert(x);
    medians.add(h.getMedian());
  }
  check(medians, [5.0, 7.5, 10.0, 55.0, 10.0, 11.5, 13.0]);
}
