// Search For Range: first and last index of target in a sorted array, or [-1, -1].
// Two binary searches (lower bound and upper bound). O(log n) time, O(1) space.

List<int> searchForRange(List<int> array, int target) {
  /// First index whose value is >= [value] (array.length if none).
  int lowerBound(int value) {
    var lo = 0, hi = array.length; // half-open [lo, hi)
    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (array[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  final first = lowerBound(target);
  if (first == array.length || array[first] != target) return [-1, -1];
  return [first, lowerBound(target + 1) - 1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const a = [0, 1, 21, 33, 45, 45, 45, 45, 45, 45, 61, 71, 73];
  check(searchForRange(a, 45), [4, 9]);
  check(searchForRange(a, 0), [0, 0]);
  check(searchForRange(a, 73), [12, 12]);
  check(searchForRange(a, 47), [-1, -1]);
  check(searchForRange([], 1), [-1, -1]);
}
