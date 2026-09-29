// Min Heap Construction backed by a List.
// buildHeap O(n); insert/remove O(log n); peek O(1). O(1) extra space.

class MinHeap {
  MinHeap(List<int> array) : heap = buildHeap(array);
  final List<int> heap;

  /// Heapify in place: sift down every non-leaf from the bottom up. O(n) total.
  static List<int> buildHeap(List<int> array) {
    for (var i = (array.length - 2) ~/ 2; i >= 0; i--) {
      _siftDown(array, i, array.length - 1);
    }
    return array;
  }

  static void _siftDown(List<int> h, int idx, int endIdx) {
    var i = idx;
    while (true) {
      final l = 2 * i + 1, r = 2 * i + 2;
      var smallest = i;
      if (l <= endIdx && h[l] < h[smallest]) smallest = l;
      if (r <= endIdx && h[r] < h[smallest]) smallest = r;
      if (smallest == i) return;
      _swap(h, i, smallest);
      i = smallest;
    }
  }

  static void _siftUp(List<int> h, int idx) {
    var i = idx;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (h[parent] <= h[i]) return;
      _swap(h, i, parent);
      i = parent;
    }
  }

  static void _swap(List<int> h, int i, int j) {
    final t = h[i];
    h[i] = h[j];
    h[j] = t;
  }

  int get length => heap.length;
  bool get isEmpty => heap.isEmpty;
  int peek() => heap.first;

  int remove() {
    _swap(heap, 0, heap.length - 1);
    final min = heap.removeLast();
    _siftDown(heap, 0, heap.length - 1);
    return min;
  }

  void insert(int value) {
    heap.add(value);
    _siftUp(heap, heap.length - 1);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final h = MinHeap([48, 12, 24, 7, 8, -5, 24, 391, 24, 56, 2, 6, 8, 41]);
  h.insert(76);
  check(h.peek(), -5);
  check(h.remove(), -5);
  check(h.peek(), 2);
  h.insert(-100);
  final drained = <int>[];
  while (!h.isEmpty) {
    drained.add(h.remove());
  }
  check(drained, [-100, 2, 6, 7, 8, 8, 12, 24, 24, 24, 41, 48, 56, 76, 391]);
}
