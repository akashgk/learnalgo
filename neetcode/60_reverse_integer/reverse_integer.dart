// Reverse Integer: reverse the digits of a signed 32-bit integer; return 0 if the result leaves the
// 32-bit range. Written as if only 32-bit arithmetic were available: check for overflow BEFORE
// multiplying by 10. O(number of digits).

const _max = 2147483647, _min = -2147483648;

int reverse(int x) {
  var result = 0;
  while (x != 0) {
    final digit = x.remainder(10); // keeps the sign of x (Dart's % would not)
    x = x ~/ 10; // truncates toward zero
    // result * 10 + digit must stay within [_min, _max].
    if (result > _max ~/ 10 || (result == _max ~/ 10 && digit > 7)) return 0;
    if (result < _min ~/ 10 || (result == _min ~/ 10 && digit < -8)) return 0;
    result = result * 10 + digit;
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(reverse(123), 321);
  check(reverse(-123), -321);
  check(reverse(120), 21);
  check(reverse(0), 0);
  check(reverse(1534236469), 0); // 9646324351 overflows
  check(reverse(-2147483412), -2143847412); // fits
  check(reverse(1463847412), 2147483641); // fits, just under the limit
}
