// Maximize Expression: max of a - b + c - d with indices a < b < c < d (0 if fewer than 4).
// Four running-max passes; each builds on the previous term. O(n) time, O(n) space.

int maximizeExpression(List<int> array) {
  if (array.length < 4) return 0;
  const negInf = -(1 << 62);
  final n = array.length;
  final a = List<int>.filled(n, negInf); // best A up to i
  final ab = List<int>.filled(n, negInf); // best A - B up to i
  final abc = List<int>.filled(n, negInf); // best A - B + C up to i
  final abcd = List<int>.filled(n, negInf); // best A - B + C - D up to i
  int max(int x, int y) => x > y ? x : y;
  for (var i = 0; i < n; i++) {
    final v = array[i];
    a[i] = max(i > 0 ? a[i - 1] : negInf, v);
    if (i >= 1) ab[i] = max(i > 1 ? ab[i - 1] : negInf, a[i - 1] - v);
    if (i >= 2) abc[i] = max(i > 2 ? abc[i - 1] : negInf, ab[i - 1] + v);
    if (i >= 3) abcd[i] = max(i > 3 ? abcd[i - 1] : negInf, abc[i - 1] - v);
  }
  return abcd[n - 1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maximizeExpression([3, 6, 1, -3, 2, 7]), 4); // 6 - (-3) + 2 - 7
  check(maximizeExpression([1, 2]), 0);
  check(maximizeExpression([1, 1, 1, 1]), 0);
  check(maximizeExpression([10, 0, 10, 0]), 20);
}
