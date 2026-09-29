// Bubble Sort (in place). Repeatedly swap adjacent out-of-order pairs; stop early when a
// pass makes no swaps. O(n^2) worst/avg, O(n) best (already sorted), O(1) space. Stable.

List<int> bubbleSort(List<int> array) {
  var sortedTail = 0;
  var swapped = true;
  while (swapped) {
    swapped = false;
    for (var i = 0; i < array.length - 1 - sortedTail; i++) {
      if (array[i] > array[i + 1]) {
        final tmp = array[i];
        array[i] = array[i + 1];
        array[i + 1] = tmp;
        swapped = true;
      }
    }
    sortedTail++; // the largest remaining element has bubbled to the end
  }
  return array;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(bubbleSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(bubbleSort([1, 2, 3]), [1, 2, 3]);
  check(bubbleSort([]), []);
}
