// Sweet And Savory: sweet dishes are negative, savory positive. Find the pair
// [sweet, savory] whose sum is closest to target without exceeding it; [0, 0] if none.
// Sort sweets by closeness to 0 and savories ascending, then two pointers.
// O(n log n) time, O(n) space.

List<int> sweetAndSavory(List<int> dishes, int target) {
  final sweet = dishes.where((d) => d < 0).toList()..sort((a, b) => b.compareTo(a)); // -1, -3, ...
  final savory = dishes.where((d) => d > 0).toList()..sort(); // 1, 2, ...
  var best = [0, 0];
  var bestGap = double.maxFinite.toInt();
  var i = 0, j = 0;
  while (i < sweet.length && j < savory.length) {
    final sum = sweet[i] + savory[j];
    if (sum <= target) {
      final gap = target - sum;
      if (gap < bestGap) {
        bestGap = gap;
        best = [sweet[i], savory[j]];
      }
      j++; // try a bigger savory to get closer to target
    } else {
      i++; // too big: use a more negative sweet
    }
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sweetAndSavory([-3, -5, 1, 7], 8), [-3, 7]);
  check(sweetAndSavory([3, 5, 7, 2, 6, -10, -4, -7, 20], 4), [-4, 7]); // -4 + 7 = 3 is the largest sum <= 4
  check(sweetAndSavory([2, 5, -4, -7, 12, 100, -25], -20), [-25, 5]);
  check(sweetAndSavory([-5, 10], 4), [0, 0]);
  check(sweetAndSavory([1, 2], 10), [0, 0]);
}
