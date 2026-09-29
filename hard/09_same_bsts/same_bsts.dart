// Same BSTs: would inserting arrayOne and arrayTwo (in order) into empty BSTs produce the
// same tree? Compare roots, then recursively compare the "smaller" and ">= root" subsequences
// using index pointers instead of new arrays. O(n^2) time, O(d) space.

bool sameBsts(List<int> arrayOne, List<int> arrayTwo) {
  if (arrayOne.length != arrayTwo.length) return false;
  if (arrayOne.isEmpty) return true;
  return _same(arrayOne, arrayTwo, 0, 0, null, null);
}

/// Compares the subtrees rooted at the first element of each array (at or after rootIdx)
/// whose value lies within [min, max).
bool _same(List<int> a, List<int> b, int? rootA, int? rootB, int? min, int? max) {
  if (rootA == null || rootB == null) return rootA == rootB;
  if (a[rootA] != b[rootB]) return false;
  final value = a[rootA];
  final leftA = _firstSmaller(a, rootA, min), leftB = _firstSmaller(b, rootB, min);
  final rightA = _firstBiggerOrEqual(a, rootA, max), rightB = _firstBiggerOrEqual(b, rootB, max);
  return _same(a, b, leftA, leftB, min, value) && _same(a, b, rightA, rightB, value, max);
}

/// First index after [start] whose value is smaller than a[start] and >= min.
int? _firstSmaller(List<int> a, int start, int? min) {
  for (var i = start + 1; i < a.length; i++) {
    if (a[i] < a[start] && (min == null || a[i] >= min)) return i;
  }
  return null;
}

/// First index after [start] whose value is >= a[start] and < max.
int? _firstBiggerOrEqual(List<int> a, int start, int? max) {
  for (var i = start + 1; i < a.length; i++) {
    if (a[i] >= a[start] && (max == null || a[i] < max)) return i;
  }
  return null;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(sameBsts([10, 15, 8, 12, 94, 81, 5, 2, 11], [10, 8, 5, 15, 2, 12, 11, 94, 81]), true);
  check(sameBsts([10, 15, 8, 12, 94, 81, 5, 2, 11], [10, 8, 5, 15, 2, 12, 94, 81, 11]), true);
  check(sameBsts([10, 15, 8, 12, 94, 81, 5, 2, 11], [10, 8, 5, 15, 2, 11, 12, 94, 81]), false);
  check(sameBsts([], []), true);
  check(sameBsts([1, 2], [2, 1]), false);
}
