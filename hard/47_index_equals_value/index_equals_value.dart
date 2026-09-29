// Index Equals Value: sorted array of DISTINCT integers; return the smallest i with a[i] == i,
// or -1. a[i] - i is non-decreasing, so binary search for the first zero.
// O(log n) time, O(1) space.

int indexEqualsValue(List<int> array) {
  var lo = 0, hi = array.length - 1, answer = -1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (array[mid] < mid) {
      lo = mid + 1;
    } else {
      if (array[mid] == mid) answer = mid; // candidate; keep looking left for a smaller one
      hi = mid - 1;
    }
  }
  return answer;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(indexEqualsValue([-5, -3, 0, 3, 4, 5, 9]), 3);
  check(indexEqualsValue([0, 1, 2, 3]), 0);
  check(indexEqualsValue([-1, 0, 1]), -1);
  check(indexEqualsValue([]), -1);
}
