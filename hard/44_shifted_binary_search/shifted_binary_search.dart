// Shifted Binary Search: sorted array of distinct ints rotated by an unknown amount.
// At every step one half is sorted; decide if the target lies in it. O(log n) time, O(1) space.

int shiftedBinarySearch(List<int> array, int target) {
  var lo = 0, hi = array.length - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (array[mid] == target) return mid;
    if (array[lo] <= array[mid]) {
      // left half [lo, mid] is sorted
      if (array[lo] <= target && target < array[mid]) {
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    } else {
      // right half [mid, hi] is sorted
      if (array[mid] < target && target <= array[hi]) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
  }
  return -1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const a = [45, 61, 71, 72, 73, 0, 1, 21, 33, 37];
  check(shiftedBinarySearch(a, 33), 8);
  check(shiftedBinarySearch(a, 45), 0);
  check(shiftedBinarySearch(a, 0), 5);
  check(shiftedBinarySearch(a, 38), -1);
  check(shiftedBinarySearch([5], 5), 0);
}
