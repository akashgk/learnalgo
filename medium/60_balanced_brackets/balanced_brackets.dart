// Balanced Brackets: (), [], {} properly nested; other characters are ignored.
// Stack of expected closers. O(n) time, O(n) space.

bool balancedBrackets(String string) {
  const pairs = {')': '(', ']': '[', '}': '{'};
  const openers = {'(', '[', '{'};
  final stack = <String>[];
  for (final ch in string.split('')) {
    if (openers.contains(ch)) {
      stack.add(ch);
    } else if (pairs.containsKey(ch)) {
      if (stack.isEmpty || stack.removeLast() != pairs[ch]) return false;
    }
  }
  return stack.isEmpty; // unmatched openers left over means unbalanced
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(balancedBrackets('([])(){}(())()()'), true);
  check(balancedBrackets('(a[b]c)'), true);
  check(balancedBrackets('([)]'), false);
  check(balancedBrackets('(('), false);
  check(balancedBrackets(')'), false);
  check(balancedBrackets(''), true);
}
