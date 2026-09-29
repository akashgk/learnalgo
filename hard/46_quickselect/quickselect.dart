// Quickselect: k-th smallest (1-based) in O(n) average time, O(n^2) worst, O(1) extra space.
// Random pivot + Lomuto partition, iterating on the side that contains index k - 1.

import 'dart:math';

int quickselect(List<int> array, int k) {
  final a = [...array];
  final target = k - 1;
  final rng = Random(42);
  var lo = 0, hi = a.length - 1;
  while (true) {
    final p = _partition(a, lo, hi, lo + rng.nextInt(hi - lo + 1));
    if (p == target) return a[p];
    if (p < target) {
      lo = p + 1;
    } else {
      hi = p - 1;
    }
  }
}

/// Moves a[pivotIdx] to its sorted position within [lo, hi] and returns that position.
int _partition(List<int> a, int lo, int hi, int pivotIdx) {
  _swap(a, pivotIdx, hi);
  final pivot = a[hi];
  var store = lo;
  for (var i = lo; i < hi; i++) {
    if (a[i] < pivot) _swap(a, i, store++);
  }
  _swap(a, store, hi);
  return store;
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const input = [8, 5, 2, 9, 7, 6, 3];
  check(quickselect(input, 3), 5);
  check(quickselect(input, 1), 2);
  check(quickselect(input, 7), 9);
  check(quickselect([1, 1, 1], 2), 1);
  final sorted = [...input]..sort();
  for (var k = 1; k <= input.length; k++) {
    if (quickselect(input, k) != sorted[k - 1]) throw StateError('mismatch at k=$k');
  }
  print('ok: all k');
}
