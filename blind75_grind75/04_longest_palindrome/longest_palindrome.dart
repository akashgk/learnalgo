// Longest Palindrome (LeetCode 409): length of the longest palindrome that can be BUILT from the
// letters of s (case-sensitive), using each letter at most as often as it appears.
// Every pair of equal letters can be placed symmetrically; one odd leftover can sit in the middle.
// O(n) time, O(1) space (52 letters).

int longestPalindrome(String s) {
  final count = <int, int>{};
  for (final c in s.codeUnits) {
    count[c] = (count[c] ?? 0) + 1;
  }
  var length = 0;
  var hasOdd = false;
  for (final c in count.values) {
    length += c ~/ 2 * 2; // all complete pairs
    if (c.isOdd) hasOdd = true;
  }
  return hasOdd ? length + 1 : length; // one leftover letter in the center
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestPalindrome('abccccdd'), 7); // "dccaccd"
  check(longestPalindrome('a'), 1);
  check(longestPalindrome('Aa'), 1); // case-sensitive
  check(longestPalindrome('aaabbb'), 5); // "abbba" style: 2 + 2 pairs + 1 center
  check(longestPalindrome('bb'), 2);
}
