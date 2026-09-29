// Right Smaller Than: for each index, how many elements to its right are strictly smaller.
// Merge sort on indices; while merging, every element taken from the right half before a left
// element is smaller and to its right. O(n log n) time, O(n) space.

List<int> rightSmallerThan(List<int> array) {
  final counts = List<int>.filled(array.length, 0);

  List<int> sort(List<int> ids) {
    if (ids.length <= 1) return ids;
    final mid = ids.length ~/ 2;
    final left = sort(ids.sublist(0, mid)), right = sort(ids.sublist(mid));
    final out = <int>[];
    var i = 0, j = 0;
    while (i < left.length || j < right.length) {
      if (j == right.length || (i < left.length && array[left[i]] <= array[right[j]])) {
        counts[left[i]] += j; // right[0..j) are smaller than left[i] and positioned after it
        out.add(left[i++]);
      } else {
        out.add(right[j++]);
      }
    }
    return out;
  }

  sort(List<int>.generate(array.length, (i) => i));
  return counts;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(rightSmallerThan([8, 5, 11, -1, 3, 4, 2]), [5, 4, 4, 0, 1, 1, 0]);
  check(rightSmallerThan([]), []);
  check(rightSmallerThan([1, 1, 1]), [0, 0, 0]);
  check(rightSmallerThan([3, 2, 1]), [2, 1, 0]);
}
