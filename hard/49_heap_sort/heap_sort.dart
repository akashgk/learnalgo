// Heap Sort (in place). Build a max-heap in O(n), then repeatedly swap the max to the end
// and sift down. O(n log n) time in all cases, O(1) space. Not stable.

List<int> heapSort(List<int> array) {
  final n = array.length;
  for (var i = (n - 2) ~/ 2; i >= 0; i--) {
    _siftDown(array, i, n - 1);
  }
  for (var end = n - 1; end > 0; end--) {
    _swap(array, 0, end); // current max goes to its final position
    _siftDown(array, 0, end - 1);
  }
  return array;
}

void _siftDown(List<int> a, int i, int endIdx) {
  while (true) {
    final l = 2 * i + 1, r = l + 1;
    var largest = i;
    if (l <= endIdx && a[l] > a[largest]) largest = l;
    if (r <= endIdx && a[r] > a[largest]) largest = r;
    if (largest == i) return;
    _swap(a, i, largest);
    i = largest;
  }
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
  check(heapSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(heapSort([]), []);
  check(heapSort([2, 1]), [1, 2]);
}
