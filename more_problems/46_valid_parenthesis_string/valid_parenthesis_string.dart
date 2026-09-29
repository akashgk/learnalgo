// Valid Parenthesis String: '(' , ')' and '*' where '*' may be '(', ')' or empty. Can it be balanced?
// Greedy range tracking: keep the minimum and maximum possible number of unmatched '('.
// O(n) time, O(1) space.

bool checkValidString(String s) {
  var lo = 0, hi = 0; // the set of reachable open counts is exactly [lo, hi]
  for (final ch in s.split('')) {
    if (ch == '(') {
      lo++;
      hi++;
    } else if (ch == ')') {
      lo--;
      hi--;
    } else {
      lo--; // '*' as ')'
      hi++; // '*' as '('
    }
    if (hi < 0) return false; // even treating every '*' as '(' we have too many ')'
    if (lo < 0) lo = 0; // a negative open count is not a real state; drop it
  }
  return lo == 0; // some choice closes everything
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(checkValidString('()'), true);
  check(checkValidString('(*)'), true);
  check(checkValidString('(*))'), true);
  check(checkValidString('((*'), false);
  check(checkValidString('*)('), false); // the final '(' can never close
  check(checkValidString(''), true);
  check(checkValidString('(*()'), true); // '*' as empty
  check(checkValidString('**))'), true); // both stars as '('
}
