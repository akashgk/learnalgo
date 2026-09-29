// Reverse Polish Notation evaluation. Stack of operands; operators pop two.
// Division truncates toward zero. O(n) time, O(n) space.

int reversePolishNotation(List<String> tokens) {
  final stack = <int>[];
  for (final token in tokens) {
    if (const {'+', '-', '*', '/'}.contains(token)) {
      final right = stack.removeLast(), left = stack.removeLast(); // order matters
      stack.add(switch (token) {
        '+' => left + right,
        '-' => left - right,
        '*' => left * right,
        _ => left ~/ right,
      });
    } else {
      stack.add(int.parse(token));
    }
  }
  return stack.single;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(reversePolishNotation(['50', '3', '17', '+', '2', '-', '/']), 2);
  check(reversePolishNotation(['4', '-7', '/']), 0);
  check(reversePolishNotation(['2', '1', '+', '3', '*']), 9);
  check(reversePolishNotation(['-7', '2', '/']), -3);
}
