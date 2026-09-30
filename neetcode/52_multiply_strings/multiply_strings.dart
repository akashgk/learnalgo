// Multiply Strings: multiply two non-negative integers given as strings, without converting them
// to big integers. Grade-school multiplication: the product of digits i and j (from the right)
// lands in position i + j of the result. O(m * n) time, O(m + n) space.

String multiply(String num1, String num2) {
  if (num1 == '0' || num2 == '0') return '0';
  final m = num1.length, n = num2.length;
  final result = List<int>.filled(m + n, 0); // a product has at most m + n digits
  for (var i = m - 1; i >= 0; i--) {
    final a = num1.codeUnitAt(i) - 48;
    for (var j = n - 1; j >= 0; j--) {
      final b = num2.codeUnitAt(j) - 48;
      // Positions counted from the left: digits i and j contribute to i + j + 1, carry to i + j.
      final sum = a * b + result[i + j + 1];
      result[i + j + 1] = sum % 10;
      result[i + j] += sum ~/ 10;
    }
  }
  final start = result[0] == 0 ? 1 : 0; // at most one leading zero
  return result.sublist(start).join();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(multiply('2', '3'), '6');
  check(multiply('123', '456'), '56088');
  check(multiply('0', '52'), '0');
  check(multiply('99', '99'), '9801');
  check(multiply('123456789', '987654321'), '121932631112635269');
}
