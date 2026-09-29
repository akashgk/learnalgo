// Selection Sort (in place). Repeatedly select the minimum of the unsorted suffix and swap
// it to the front. O(n^2) always, O(1) space, at most n - 1 swaps. Not stable.

List<int> selectionSort(List<int> array) {
  for (var start = 0; start < array.length - 1; start++) {
    var minIdx = start;
    for (var i = start + 1; i < array.length; i++) {
      if (array[i] < array[minIdx]) minIdx = i;
    }
    if (minIdx != start) {
      final tmp = array[start];
      array[start] = array[minIdx];
      array[minIdx] = tmp;
    }
  }
  return array;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(selectionSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(selectionSort([2, 1]), [1, 2]);
  check(selectionSort([]), []);
}
