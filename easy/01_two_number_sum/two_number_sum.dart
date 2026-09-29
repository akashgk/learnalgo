// Two Number Sum
// Optimal: single pass with a hash set. O(n) time, O(n) space.
// Alternative: sort + two pointers. O(n log n) time, O(1) extra space.

/// Returns the pair that sums to [target], or an empty list if none exists.
List<int> twoNumberSum(List<int> array, int target) {
  final seen = <int>{};
  for (final x in array) {
    final need = target - x;
    if (seen.contains(need)) return [need, x];
    seen.add(x);
  }
  return [];
}

/// Two-pointer variant. Sorts a copy so the caller's list is untouched.
List<int> twoNumberSumSorted(List<int> array, int target) {
  final a = [...array]..sort();
  var lo = 0, hi = a.length - 1;
  while (lo < hi) {
    final sum = a[lo] + a[hi];
    if (sum == target) return [a[lo], a[hi]];
    if (sum < target) {
      lo++;
    } else {
      hi--;
    }
  }
  return [];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(twoNumberSum([3, 5, -4, 8, 11, 1, -1, 6], 10), [11, -1]);
  check(twoNumberSumSorted([3, 5, -4, 8, 11, 1, -1, 6], 10), [-1, 11]);
  check(twoNumberSum([1, 2, 3], 100), []);
  check(twoNumberSum([5], 10), []); // cannot reuse the same element
}
