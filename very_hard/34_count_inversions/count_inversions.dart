// Count Inversions: pairs i < j with array[i] > array[j]. Merge sort, counting cross pairs
// during each merge. O(n log n) time, O(n) space. Does not mutate the input.

int countInversions(List<int> array) {
  int sortAndCount(List<int> a, int start, int end) {
    if (end - start <= 1) return 0;
    final mid = (start + end) ~/ 2;
    var count = sortAndCount(a, start, mid) + sortAndCount(a, mid, end);
    final merged = <int>[];
    var i = start, j = mid;
    while (i < mid && j < end) {
      if (a[i] <= a[j]) {
        merged.add(a[i++]);
      } else {
        count += mid - i; // a[j] is smaller than every remaining left element
        merged.add(a[j++]);
      }
    }
    merged
      ..addAll(a.sublist(i, mid))
      ..addAll(a.sublist(j, end));
    a.setRange(start, end, merged);
    return count;
  }

  return sortAndCount([...array], 0, array.length);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(countInversions([2, 3, 3, 1, 9, 5, 6]), 5);
  check(countInversions([]), 0);
  check(countInversions([5, 4, 3, 2, 1]), 10);
  check(countInversions([1, 1, 1]), 0);
}
