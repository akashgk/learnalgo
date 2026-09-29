// Longest Palindromic Substring: expand around each of the 2n - 1 centers.
// O(n^2) time, O(1) space.

String longestPalindromicSubstring(String string) {
  if (string.isEmpty) return '';
  var bestLo = 0, bestHi = 0; // inclusive bounds of the best palindrome

  (int, int) expand(int lo, int hi) {
    while (lo >= 0 && hi < string.length && string[lo] == string[hi]) {
      lo--;
      hi++;
    }
    return (lo + 1, hi - 1);
  }

  for (var i = 0; i < string.length; i++) {
    for (final (lo, hi) in [expand(i, i), expand(i, i + 1)]) {
      // odd and even centers
      if (hi - lo > bestHi - bestLo) (bestLo, bestHi) = (lo, hi);
    }
  }
  return string.substring(bestLo, bestHi + 1);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestPalindromicSubstring('abaxyzzyxf'), 'xyzzyx');
  check(longestPalindromicSubstring('a'), 'a');
  check(longestPalindromicSubstring('abcdefgfedcba'), 'abcdefgfedcba');
  check(longestPalindromicSubstring('it\'s highnoon'), 'noon');
}
