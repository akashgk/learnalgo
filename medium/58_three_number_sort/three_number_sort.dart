// Three Number Sort: sort `array` so its values follow the order given in `order` (3 values).
// Dutch national flag partition in one pass. O(n) time, O(1) space.

List<int> threeNumberSort(List<int> array, List<int> order) {
  final [first, second, _] = order;
  var lo = 0, mid = 0, hi = array.length - 1;
  // Invariant: [0, lo) first, [lo, mid) second, (hi, end] third, [mid, hi] unknown.
  while (mid <= hi) {
    final v = array[mid];
    if (v == first) {
      _swap(array, lo++, mid++);
    } else if (v == second) {
      mid++;
    } else {
      _swap(array, mid, hi--); // do not advance mid: the swapped-in value is unexamined
    }
  }
  return array;
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
  check(threeNumberSort([1, 0, 0, -1, -1, 0, 1, 1], [0, 1, -1]), [0, 0, 0, 1, 1, 1, -1, -1]);
  check(threeNumberSort([], [0, 7, 9]), []);
  check(threeNumberSort([7, 8, 9, 7, 8, 9, 9, 9], [8, 7, 9]), [8, 8, 7, 7, 9, 9, 9, 9]);
}
