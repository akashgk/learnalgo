// Basic Calculator (LeetCode 224): evaluate an expression with non-negative integers, '+', '-',
// parentheses, unary minus (e.g. "-(2 + 3)"), and spaces. No multiplication or division.
// One pass with a running result, the current sign, and a stack that saves (result, sign) when a
// parenthesis opens. O(n) time, O(n) space for nested parentheses.

int calculate(String s) {
  var result = 0; // value of the current parenthesis level so far
  var sign = 1; // sign to apply to the next number at this level
  final stack = <int>[]; // saved [result, sign] pairs, flattened
  var i = 0;
  while (i < s.length) {
    final ch = s[i];
    if (ch == ' ') {
      i++;
    } else if (_isDigit(ch)) {
      var number = 0;
      while (i < s.length && _isDigit(s[i])) {
        number = number * 10 + s.codeUnitAt(i) - 48;
        i++;
      }
      result += sign * number;
    } else if (ch == '+' || ch == '-') {
      sign = ch == '+' ? 1 : -1;
      i++;
    } else if (ch == '(') {
      // Save the outer level; the inner expression starts from scratch.
      stack
        ..add(result)
        ..add(sign);
      result = 0;
      sign = 1;
      i++;
    } else {
      // ')': inner value times the sign that preceded '(', added to the saved outer result.
      final outerSign = stack.removeLast(), outerResult = stack.removeLast();
      result = outerResult + outerSign * result;
      i++;
    }
  }
  return result;
}

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(calculate('1 + 1'), 2);
  check(calculate(' 2-1 + 2 '), 3);
  check(calculate('(1+(4+5+2)-3)+(6+8)'), 23);
  check(calculate('-(2 + 3)'), -5); // unary minus before a parenthesis
  check(calculate('1-(     -2)'), 3); // unary minus inside
  check(calculate('2147483647'), 2147483647);
  check(calculate('- (3 + (4 + 5))'), -12);
}
