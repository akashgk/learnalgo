// Wildcard Matching: '?' matches any one character, '*' matches any sequence (including empty).
// The pattern must match the whole string. DP over prefixes. O(|s| * |p|) time, O(|p|) space.

bool isMatch(String s, String p) {
  final m = p.length;
  // dp[j]: does p[0..j) match the current prefix of s?
  var dp = List<bool>.filled(m + 1, false);
  dp[0] = true;
  for (var j = 1; j <= m; j++) {
    dp[j] = dp[j - 1] && p[j - 1] == '*'; // only stars can match the empty string
  }
  for (var i = 1; i <= s.length; i++) {
    final next = List<bool>.filled(m + 1, false); // next[0] = false: empty pattern vs non-empty s
    for (var j = 1; j <= m; j++) {
      final pc = p[j - 1];
      if (pc == '*') {
        // Star matches nothing (next[j - 1]) or absorbs s[i - 1] and stays available (dp[j]).
        next[j] = next[j - 1] || dp[j];
      } else if (pc == '?' || pc == s[i - 1]) {
        next[j] = dp[j - 1];
      }
    }
    dp = next;
  }
  return dp[m];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isMatch('aa', 'a'), false);
  check(isMatch('aa', '*'), true);
  check(isMatch('cb', '?a'), false);
  check(isMatch('adceb', '*a*b'), true);
  check(isMatch('acdcb', 'a*c?b'), false);
  check(isMatch('', '***'), true);
  check(isMatch('', ''), true);
  check(isMatch('abc', 'a?c'), true);
}
