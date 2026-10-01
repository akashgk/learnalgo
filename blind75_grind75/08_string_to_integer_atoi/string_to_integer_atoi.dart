// String to Integer (atoi): skip leading spaces, read an optional sign, read digits until the first
// non-digit, and clamp to the 32-bit range [-2^31, 2^31 - 1]. No digits read means 0.
// Overflow is checked before each multiply-by-10, as in 32-bit arithmetic. O(n) time.

const _max = 2147483647, _min = -2147483648;

int myAtoi(String s) {
  var i = 0;
  while (i < s.length && s[i] == ' ') {
    i++;
  }
  var sign = 1;
  if (i < s.length && (s[i] == '+' || s[i] == '-')) {
    if (s[i] == '-') sign = -1;
    i++;
  }
  var result = 0; // accumulated as a non-negative magnitude
  while (i < s.length) {
    final d = s.codeUnitAt(i) - 48;
    if (d < 0 || d > 9) break; // first non-digit ends the number
    // result * 10 + d > 2^31 - 1 ?  (for negatives the limit is 2^31, handled by the clamp)
    if (result > (_max - d) ~/ 10) return sign == 1 ? _max : _min;
    result = result * 10 + d;
    i++;
  }
  return sign * result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(myAtoi('42'), 42);
  check(myAtoi('   -042'), -42); // leading spaces and zeros
  check(myAtoi('1337c0d3'), 1337); // stops at 'c'
  check(myAtoi('0-1'), 0);
  check(myAtoi('words and 987'), 0); // starts with a non-digit
  check(myAtoi('-91283472332'), -2147483648); // clamped
  check(myAtoi('2147483648'), 2147483647); // one past the max
  check(myAtoi('-2147483648'), -2147483648); // exactly the min
  check(myAtoi('+-12'), 0); // a second sign is a non-digit
  check(myAtoi(''), 0);
}
