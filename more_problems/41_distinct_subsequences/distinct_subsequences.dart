// Distinct Subsequences: number of distinct ways (index sets) to pick t as a subsequence of s.
// dp[i][j] = ways to form t[0..j) from s[0..i). O(|s| * |t|) time, O(|t|) space with a 1-D row.

int numDistinct(String s, String t) {
  final m = t.length;
  final dp = List<int>.filled(m + 1, 0);
  dp[0] = 1; // one way to form the empty string: pick nothing
  for (var i = 0; i < s.length; i++) {
    // Backwards so dp[j - 1] is still the value from before s[i] was considered.
    for (var j = m; j >= 1; j--) {
      if (s[i] == t[j - 1]) dp[j] += dp[j - 1]; // use s[i] as t[j-1], or skip it (already in dp[j])
    }
  }
  return dp[m];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(numDistinct('rabbbit', 'rabbit'), 3);
  check(numDistinct('babgbag', 'bag'), 5);
  check(numDistinct('abc', ''), 1);
  check(numDistinct('', 'a'), 0);
  check(numDistinct('aaaa', 'aa'), 6); // C(4, 2)
}
