// Longest Palindromic Subsequence: length of the longest subsequence that reads the same both ways.
// Interval DP: dp[i][j] = LPS length of s[i..j]. O(n^2) time, O(n^2) space (O(n) possible).

int longestPalindromeSubseq(String s) {
  final n = s.length;
  if (n == 0) return 0;
  final dp = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var i = n - 1; i >= 0; i--) {
    dp[i][i] = 1;
    for (var j = i + 1; j < n; j++) {
      if (s[i] == s[j]) {
        dp[i][j] = dp[i + 1][j - 1] + 2; // both ends wrap the best inner palindrome (dp is 0 when empty)
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j - 1] ? dp[i + 1][j] : dp[i][j - 1]; // drop one end
      }
    }
  }
  return dp[0][n - 1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestPalindromeSubseq('bbbab'), 4); // "bbbb"
  check(longestPalindromeSubseq('cbbd'), 2); // "bb"
  check(longestPalindromeSubseq('a'), 1);
  check(longestPalindromeSubseq('agbdba'), 5); // "abdba"
  check(longestPalindromeSubseq('abcd'), 1);
  check(longestPalindromeSubseq(''), 0);
}
