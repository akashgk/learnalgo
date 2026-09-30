// Regular Expression Matching: '.' matches any single character; 'x*' matches zero or more of the
// preceding element x. The pattern must match the whole string.
// dp[i][j] = s[i..] matches p[j..] (suffix DP). O(|s| * |p|) time and space.

bool isMatch(String s, String p) {
  final m = s.length, n = p.length;
  final dp = List.generate(m + 1, (_) => List<bool>.filled(n + 1, false));
  dp[m][n] = true; // empty string matches empty pattern
  for (var i = m; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      final firstMatches = i < m && (p[j] == '.' || p[j] == s[i]);
      if (j + 1 < n && p[j + 1] == '*') {
        // "x*": use it zero times (skip both pattern chars), or consume one s char and stay on "x*".
        dp[i][j] = dp[i][j + 2] || (firstMatches && dp[i + 1][j]);
      } else {
        dp[i][j] = firstMatches && dp[i + 1][j + 1];
      }
    }
  }
  return dp[0][0];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isMatch('aa', 'a'), false);
  check(isMatch('aa', 'a*'), true);
  check(isMatch('ab', '.*'), true);
  check(isMatch('aab', 'c*a*b'), true); // c* matches nothing
  check(isMatch('mississippi', 'mis*is*p*.'), false);
  check(isMatch('', 'a*b*'), true);
  check(isMatch('ab', '.*c'), false);
}
