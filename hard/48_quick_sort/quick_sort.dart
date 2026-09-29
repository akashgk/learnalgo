// Quick Sort (in place). Hoare-style partition around the first element; recurse on the
// smaller side first so the stack depth stays O(log n).
// Average O(n log n), worst O(n^2) time. Not stable.

List<int> quickSort(List<int> array) {
  _sort(array, 0, array.length - 1);
  return array;
}

void _sort(List<int> a, int start, int end) {
  while (start < end) {
    final pivot = a[start];
    var left = start + 1, right = end;
    while (left <= right) {
      if (a[left] > pivot && a[right] < pivot) _swap(a, left, right);
      if (a[left] <= pivot) left++;
      if (a[right] >= pivot) right--;
    }
    _swap(a, start, right); // pivot lands at its final position `right`
    // Recurse into the smaller part, loop on the larger one (tail-call elimination by hand).
    if (right - start < end - right) {
      _sort(a, start, right - 1);
      start = right + 1;
    } else {
      _sort(a, right + 1, end);
      end = right - 1;
    }
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
  check(quickSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(quickSort([]), []);
  check(quickSort([1, 1, 1]), [1, 1, 1]);
  check(quickSort([5, 4, 3, 2, 1]), [1, 2, 3, 4, 5]);
}
