// Subarray Sort: smallest [start, end] that, if sorted, sorts the whole array; [-1, -1] if sorted.
// Find the min and max among out-of-order elements, then find their correct positions.
// O(n) time, O(1) space.

List<int> subarraySort(List<int> array) {
  final n = array.length;
  bool outOfOrder(int i) => (i > 0 && array[i] < array[i - 1]) || (i < n - 1 && array[i] > array[i + 1]);

  int? minBad, maxBad;
  for (var i = 0; i < n; i++) {
    if (!outOfOrder(i)) continue;
    if (minBad == null || array[i] < minBad) minBad = array[i];
    if (maxBad == null || array[i] > maxBad) maxBad = array[i];
  }
  if (minBad == null || maxBad == null) return [-1, -1];

  var start = 0;
  while (array[start] <= minBad) {
    start++;
  }
  var end = n - 1;
  while (array[end] >= maxBad) {
    end--;
  }
  return [start, end];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(subarraySort([1, 2, 4, 7, 10, 11, 7, 12, 6, 7, 16, 18, 19]), [3, 9]);
  check(subarraySort([1, 2]), [-1, -1]);
  check(subarraySort([2, 1]), [0, 1]);
  check(subarraySort([1, 2, 8, 4, 5]), [2, 4]);
}
