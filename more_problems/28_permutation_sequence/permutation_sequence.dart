// Permutation Sequence: the k-th (1-indexed) permutation of [1..n] in lexicographic order.
// Factorial number system: each block of (n-1)! permutations shares its first digit.
// O(n^2) time (list removals), O(n) space.

String getPermutation(int n, int k) {
  final digits = [for (var i = 1; i <= n; i++) i];
  final fact = List<int>.filled(n + 1, 1);
  for (var i = 1; i <= n; i++) {
    fact[i] = fact[i - 1] * i;
  }
  var rank = k - 1; // 0-indexed rank is easier to divide
  final out = StringBuffer();
  for (var remaining = n; remaining >= 1; remaining--) {
    final block = fact[remaining - 1]; // permutations per choice of the next digit
    final index = rank ~/ block;
    out.write(digits.removeAt(index));
    rank %= block;
  }
  return out.toString();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(getPermutation(3, 3), '213');
  check(getPermutation(4, 9), '2314');
  check(getPermutation(3, 1), '123');
  check(getPermutation(3, 6), '321');
  check(getPermutation(1, 1), '1');
}
