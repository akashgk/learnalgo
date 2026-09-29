// Single Cycle Check: array of jumps (wrap-around). Is there exactly one cycle visiting
// every index once? Make n jumps; must never revisit index 0 early and must end at 0.
// O(n) time, O(1) space.

bool hasSingleCycle(List<int> array) {
  final n = array.length;
  var visited = 0, idx = 0;
  while (visited < n) {
    if (visited > 0 && idx == 0) return false; // returned to start too early
    visited++;
    idx = (idx + array[idx]) % n; // Dart % is non-negative for positive n
  }
  return idx == 0;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(hasSingleCycle([2, 3, 1, -4, -4, 2]), true);
  check(hasSingleCycle([2, 2, -1]), true);
  check(hasSingleCycle([1, -1, 1, -1]), false);
  check(hasSingleCycle([0]), true);
  check(hasSingleCycle([1, 1, 1, 1, 2]), false);
}
