// Binary Search on a sorted array. Returns index or -1. O(log n) time, O(1) space.

int binarySearch(List<int> array, int target) {
  var lo = 0, hi = array.length - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2; // avoids overflow in fixed-width languages
    final value = array[mid];
    if (value == target) return mid;
    if (value < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return -1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const a = [0, 1, 21, 33, 45, 45, 61, 71, 72, 73];
  check(binarySearch(a, 33), 3);
  check(binarySearch(a, 73), 9);
  check(binarySearch(a, 0), 0);
  check(binarySearch(a, 70), -1);
  check(binarySearch([], 1), -1);
}
