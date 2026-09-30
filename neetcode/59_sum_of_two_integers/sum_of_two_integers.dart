// Sum of Two Integers without + or -: 32-bit two's complement addition from bit operations.
// a ^ b adds without carries; (a & b) << 1 is the carry. Repeat until there is no carry.
// Dart ints are 64-bit, so every step is masked to 32 bits and the result is sign-extended.
// At most 32 iterations.

int getSum(int a, int b) {
  const mask = 0xFFFFFFFF;
  a &= mask;
  b &= mask;
  while (b != 0) {
    final carry = ((a & b) << 1) & mask;
    a = (a ^ b) & mask;
    b = carry;
  }
  // Bit 31 set means a negative 32-bit number: convert back to a negative Dart int.
  return a > 0x7FFFFFFF ? a - 0x100000000 : a;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(getSum(1, 2), 3);
  check(getSum(2, 3), 5);
  check(getSum(-1, 1), 0);
  check(getSum(-5, -7), -12);
  check(getSum(-1000, 1), -999);
}
