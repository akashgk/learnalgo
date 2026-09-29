// Partition Equal Subset Sum: can the array (positive integers) be split into two subsets
// with equal sums? Equivalent to: is there a subset summing to total / 2?
// 0/1 knapsack reachability with a 1-D table iterated backwards. O(n * S) time, O(S) space.

bool canPartition(List<int> nums) {
  final total = nums.fold(0, (a, b) => a + b);
  if (total.isOdd) return false;
  final target = total ~/ 2;
  final reachable = List<bool>.filled(target + 1, false);
  reachable[0] = true; // the empty subset
  for (final x in nums) {
    // Backwards, so reachable[s - x] still describes subsets WITHOUT x (each item used once).
    for (var s = target; s >= x; s--) {
      if (reachable[s - x]) reachable[s] = true;
    }
    if (reachable[target]) return true;
  }
  return reachable[target];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(canPartition([1, 5, 11, 5]), true); // [1, 5, 5] and [11]
  check(canPartition([1, 2, 3, 5]), false); // total 11 is odd
  check(canPartition([1, 2, 5]), false); // total 8, but no subset sums to 4
  check(canPartition([2, 2]), true);
  check(canPartition([3, 3, 3, 4, 5]), true); // [3, 3, 3] and [4, 5]
  check(canPartition([100]), false);
}
