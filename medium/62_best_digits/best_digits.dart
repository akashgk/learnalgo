// Best Digits: remove exactly numDigits digits to make the largest possible number.
// Monotonic (non-increasing) stack: pop smaller digits while removals remain.
// O(n) time, O(n) space.

String bestDigits(String number, int numDigits) {
  final stack = <int>[];
  var toRemove = numDigits;
  for (final d in number.codeUnits) {
    while (toRemove > 0 && stack.isNotEmpty && stack.last < d) {
      stack.removeLast(); // a bigger digit arriving later beats a smaller digit earlier
      toRemove--;
    }
    stack.add(d);
  }
  // Still owe removals: the stack is non-increasing, so drop from the end (smallest).
  stack.length -= toRemove;
  return String.fromCharCodes(stack);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(bestDigits('462839', 2), '6839');
  check(bestDigits('54321', 2), '543');
  check(bestDigits('100', 1), '10');
  check(bestDigits('129', 3), '');
}
