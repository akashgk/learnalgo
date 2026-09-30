// Contains Duplicate: does any value appear at least twice?
// Hash set, stop at the first repeat. O(n) time, O(n) space.

bool containsDuplicate(List<int> nums) {
  final seen = <int>{};
  for (final x in nums) {
    if (!seen.add(x)) return true; // Set.add returns false when x was already present
  }
  return false;
}

/// Alternative with O(1) extra space if mutation is allowed: sort, then compare neighbors. O(n log n).
bool containsDuplicateBySorting(List<int> nums) {
  final a = [...nums]..sort();
  for (var i = 1; i < a.length; i++) {
    if (a[i] == a[i - 1]) return true;
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  for (final f in [containsDuplicate, containsDuplicateBySorting]) {
    check(f([1, 2, 3, 1]), true);
    check(f([1, 2, 3, 4]), false);
    check(f([1, 1, 1, 3, 3, 4, 3, 2, 4, 2]), true);
    check(f([]), false);
  }
}
