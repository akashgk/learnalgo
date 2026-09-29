// Number Of Binary Tree Topologies with n nodes (the nth Catalan number).
// T(n) = sum over leftSize of T(leftSize) * T(n - 1 - leftSize). O(n^2) time, O(n) space.

int numberOfBinaryTreeTopologies(int n) {
  final t = List<int>.filled(n + 1, 0)..[0] = 1;
  for (var nodes = 1; nodes <= n; nodes++) {
    for (var leftSize = 0; leftSize < nodes; leftSize++) {
      t[nodes] += t[leftSize] * t[nodes - 1 - leftSize];
    }
  }
  return t[n];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check([for (var n = 0; n <= 6; n++) numberOfBinaryTreeTopologies(n)], [1, 1, 2, 5, 14, 42, 132]);
}
