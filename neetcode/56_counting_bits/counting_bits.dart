// Counting Bits: for every i in 0..n, the number of 1 bits in i.
// DP on the binary representation: i has the same bits as i >> 1, plus its lowest bit.
// bits[i] = bits[i >> 1] + (i & 1). O(n) time.

List<int> countBits(int n) {
  final bits = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= n; i++) {
    bits[i] = bits[i >> 1] + (i & 1);
  }
  return bits;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(countBits(2), [0, 1, 1]);
  check(countBits(5), [0, 1, 1, 2, 1, 2]);
  check(countBits(0), [0]);
}
