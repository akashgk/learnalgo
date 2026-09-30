// Number of 1 Bits (Hamming weight) of a non-negative integer.
// n & (n - 1) clears the lowest set bit, so the loop runs once per 1 bit. O(number of 1 bits).

int hammingWeight(int n) {
  var count = 0;
  while (n != 0) {
    n &= n - 1;
    count++;
  }
  return count;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(hammingWeight(11), 3); // 1011
  check(hammingWeight(128), 1); // 10000000
  check(hammingWeight(2147483645), 30); // 31 bits, one of them 0
  check(hammingWeight(0), 0);
}
