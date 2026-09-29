// Palindrome Check. Two pointers from both ends. O(n) time, O(1) space.

bool isPalindrome(String string) {
  var lo = 0, hi = string.length - 1;
  while (lo < hi) {
    if (string.codeUnitAt(lo) != string.codeUnitAt(hi)) return false;
    lo++;
    hi--;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isPalindrome('abcdcba'), true);
  check(isPalindrome('abba'), true);
  check(isPalindrome('ab'), false);
  check(isPalindrome('a'), true);
  check(isPalindrome(''), true);
}
