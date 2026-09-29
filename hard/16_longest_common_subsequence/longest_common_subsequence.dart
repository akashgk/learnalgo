// Longest Common Subsequence: returns the subsequence as a list of characters.
// 2D DP table, then backtrack. O(n * m) time and space.

List<String> longestCommonSubsequence(String str1, String str2) {
  final n = str1.length, m = str2.length;
  // lcs[i][j] = LCS length of str1[0..i) and str2[0..j)
  final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      lcs[i][j] = str1[i - 1] == str2[j - 1]
          ? lcs[i - 1][j - 1] + 1
          : (lcs[i - 1][j] > lcs[i][j - 1] ? lcs[i - 1][j] : lcs[i][j - 1]);
    }
  }
  final out = <String>[];
  var i = n, j = m;
  while (i > 0 && j > 0) {
    if (str1[i - 1] == str2[j - 1]) {
      out.add(str1[i - 1]);
      i--;
      j--;
    } else if (lcs[i - 1][j] >= lcs[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }
  return out.reversed.toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestCommonSubsequence('ZXVVYZW', 'XKYKZPW').join(), 'XYZW');
  check(longestCommonSubsequence('', 'ABC'), []);
  check(longestCommonSubsequence('ABCDEFG', 'APPLES').join(), 'AE');
}
