// Insertion Sort (in place). Grow a sorted prefix; insert each new element by shifting it left.
// O(n^2) worst/avg, O(n) best, O(1) space. Stable. Great for small or nearly sorted input.

List<int> insertionSort(List<int> array) {
  for (var i = 1; i < array.length; i++) {
    final current = array[i];
    var j = i - 1;
    while (j >= 0 && array[j] > current) {
      array[j + 1] = array[j]; // shift right instead of swapping: fewer writes
      j--;
    }
    array[j + 1] = current;
  }
  return array;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(insertionSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(insertionSort([3, 2, 1]), [1, 2, 3]);
  check(insertionSort([1]), [1]);
}
