// Sorted Squared Array
// Input is sorted (may contain negatives). The largest square is at one of the two ends,
// so fill the output from the back with two pointers. O(n) time, O(n) output space.

List<int> sortedSquaredArray(List<int> array) {
  final result = List<int>.filled(array.length, 0);
  var lo = 0, hi = array.length - 1;
  for (var write = array.length - 1; write >= 0; write--) {
    final left = array[lo].abs(), right = array[hi].abs();
    if (left > right) {
      result[write] = left * left;
      lo++;
    } else {
      result[write] = right * right;
      hi--;
    }
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sortedSquaredArray([1, 2, 3, 5, 6, 8, 9]), [1, 4, 9, 25, 36, 64, 81]);
  check(sortedSquaredArray([-7, -3, 1, 9, 22, 30]), [1, 9, 49, 81, 484, 900]);
  check(sortedSquaredArray([-5, -4, -3, -2, -1]), [1, 4, 9, 16, 25]);
  check(sortedSquaredArray([]), []);
  check(sortedSquaredArray([0]), [0]);
}
