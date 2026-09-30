// Pow(x, n): x raised to an integer power n (n may be negative).
// Fast exponentiation (exponentiation by squaring): process n's bits; square the base each step
// and multiply it in when the bit is 1. O(log |n|) multiplications, O(1) space.

double myPow(double x, int n) {
  var e = n.abs(); // Dart ints are 64-bit, so |n| for a 32-bit n never overflows
  var base = x, result = 1.0;
  while (e > 0) {
    if (e & 1 == 1) result *= base; // this bit contributes base^(2^k)
    base *= base;
    e >>= 1;
  }
  return n < 0 ? 1 / result : result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(myPow(2, 10), 1024.0);
  check(myPow(2.1, 3).toStringAsFixed(5), '9.26100');
  check(myPow(2, -2), 0.25);
  check(myPow(5, 0), 1.0);
  check(myPow(1, -2147483648), 1.0); // the most negative 32-bit exponent
  check(myPow(-2, 3), -8.0);
}
