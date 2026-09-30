// Valid Palindrome: after lowercasing and removing every non-alphanumeric character,
// does the string read the same both ways? Two pointers that skip ignored characters.
// O(n) time, O(1) extra space (no cleaned copy).

bool isPalindrome(String s) {
  var lo = 0, hi = s.length - 1;
  while (lo < hi) {
    if (!_isAlnum(s.codeUnitAt(lo))) {
      lo++;
    } else if (!_isAlnum(s.codeUnitAt(hi))) {
      hi--;
    } else {
      if (_lower(s.codeUnitAt(lo)) != _lower(s.codeUnitAt(hi))) return false;
      lo++;
      hi--;
    }
  }
  return true;
}

bool _isAlnum(int c) => (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);

/// ASCII lowercase: 'A'..'Z' (65..90) differ from 'a'..'z' by 32.
int _lower(int c) => (c >= 65 && c <= 90) ? c + 32 : c;

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isPalindrome('A man, a plan, a canal: Panama'), true);
  check(isPalindrome('race a car'), false);
  check(isPalindrome(' '), true); // empty after cleaning
  check(isPalindrome('0P'), false); // digits count, and '0' != 'p'
  check(isPalindrome('.,'), true);
}
