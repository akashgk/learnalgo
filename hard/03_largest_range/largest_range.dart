// Largest Range: longest run of consecutive integers present in the array (any order).
// Hash set; only start expanding from numbers whose predecessor is absent.
// O(n) time, O(n) space.

List<int> largestRange(List<int> array) {
  final nums = array.toSet();
  var best = [array[0], array[0]];
  for (final x in nums) {
    if (nums.contains(x - 1)) continue; // not the start of a run
    var end = x;
    while (nums.contains(end + 1)) {
      end++;
    }
    if (end - x > best[1] - best[0]) best = [x, end];
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(largestRange([1, 11, 3, 0, 15, 5, 2, 4, 10, 7, 12, 6]), [0, 7]);
  check(largestRange([1]), [1, 1]);
  check(largestRange([4, 2, 1, 3, 6]), [1, 4]);
}
