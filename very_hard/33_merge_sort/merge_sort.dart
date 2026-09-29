// Merge Sort with a single auxiliary buffer, alternating roles between levels to avoid copies.
// O(n log n) time in all cases, O(n) space. Stable.

List<int> mergeSort(List<int> array) {
  if (array.length <= 1) return array;
  final aux = [...array];
  _sort(array, 0, array.length - 1, aux);
  return array;
}

/// Sorts main[start..end] using aux (which holds the same values) as the source.
void _sort(List<int> main, int start, int end, List<int> aux) {
  if (start == end) return;
  final mid = (start + end) ~/ 2;
  _sort(aux, start, mid, main); // swap roles: sort halves into aux
  _sort(aux, mid + 1, end, main);
  var i = start, j = mid + 1, k = start;
  while (i <= mid && j <= end) {
    main[k++] = aux[i] <= aux[j] ? aux[i++] : aux[j++]; // <= keeps it stable
  }
  while (i <= mid) {
    main[k++] = aux[i++];
  }
  while (j <= end) {
    main[k++] = aux[j++];
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(mergeSort([8, 5, 2, 9, 5, 6, 3]), [2, 3, 5, 5, 6, 8, 9]);
  check(mergeSort([]), []);
  check(mergeSort([2, 1]), [1, 2]);
  check(mergeSort([5, -1, 5, 0, -1]), [-1, -1, 0, 5, 5]);
}
