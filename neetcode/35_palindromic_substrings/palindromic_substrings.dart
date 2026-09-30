// Palindromic Substrings: count substrings (by position) that are palindromes.
// Expand around each of the 2n - 1 centers (every character, and every gap between characters).
// O(n^2) time, O(1) space.

int countSubstrings(String s) {
  var count = 0;
  for (var center = 0; center < 2 * s.length - 1; center++) {
    // Even centers sit on a character (odd length); odd centers sit between two (even length).
    var lo = center ~/ 2, hi = lo + center % 2;
    while (lo >= 0 && hi < s.length && s[lo] == s[hi]) {
      count++; // s[lo..hi] is a palindrome; try one step wider
      lo--;
      hi++;
    }
  }
  return count;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(countSubstrings('abc'), 3);
  check(countSubstrings('aaa'), 6); // a, a, a, aa, aa, aaa
  check(countSubstrings('abba'), 6); // a, b, b, a, bb, abba
  check(countSubstrings(''), 0);
}
