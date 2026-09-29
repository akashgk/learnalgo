// Three Number Sum: all triplets (ascending, distinct values) summing to target.
// Sort, fix one element, two-pointer the rest. O(n^2) time, O(n) space for output.

List<List<int>> threeNumberSum(List<int> array, int targetSum) {
  final a = [...array]..sort();
  final triplets = <List<int>>[];
  for (var i = 0; i < a.length - 2; i++) {
    var lo = i + 1, hi = a.length - 1;
    while (lo < hi) {
      final sum = a[i] + a[lo] + a[hi];
      if (sum == targetSum) {
        triplets.add([a[i], a[lo], a[hi]]);
        lo++;
        hi--;
      } else if (sum < targetSum) {
        lo++;
      } else {
        hi--;
      }
    }
  }
  return triplets;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(threeNumberSum([12, 3, 1, 2, -6, 5, -8, 6], 0), [
    [-8, 2, 6],
    [-8, 3, 5],
    [-6, 1, 5],
  ]);
  check(threeNumberSum([1, 2, 3], 7), []);
  check(threeNumberSum([1, 2, 3, 4, 5, 6, 7, 8, 9, 15], 18), [
    [1, 2, 15],
    [1, 8, 9],
    [2, 7, 9],
    [3, 6, 9],
    [3, 7, 8],
    [4, 5, 9],
    [4, 6, 8],
    [5, 6, 7],
  ]);
}
