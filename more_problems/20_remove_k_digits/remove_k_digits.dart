// Remove K Digits: remove k digits from a non-negative number string to make it as small as possible.
// Greedy with a monotonic (non-decreasing) stack: drop a digit whenever a smaller digit follows it.
// O(n) time, O(n) space.

String removeKdigits(String num, int k) {
  final stack = <int>[]; // digit code units
  var toRemove = k;
  for (final c in num.codeUnits) {
    // A larger digit before a smaller one is the most valuable removal available.
    while (toRemove > 0 && stack.isNotEmpty && stack.last > c) {
      stack.removeLast();
      toRemove--;
    }
    stack.add(c);
  }
  // Still owe removals: the stack is non-decreasing, so the largest digits are at the end.
  stack.length -= toRemove;
  // Strip leading zeros.
  var start = 0;
  while (start < stack.length && stack[start] == 48) {
    start++;
  }
  final result = String.fromCharCodes(stack.sublist(start));
  return result.isEmpty ? '0' : result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(removeKdigits('1432219', 3), '1219');
  check(removeKdigits('10200', 1), '200'); // leading zeros removed
  check(removeKdigits('10', 2), '0'); // everything removed
  check(removeKdigits('12345', 2), '123'); // increasing: remove from the end
  check(removeKdigits('112', 1), '11');
  check(removeKdigits('9', 1), '0');
}
