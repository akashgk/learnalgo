// Word Break: can s be split into a sequence of dictionary words (words may be reused)?
// dp[i] = the prefix s[0..i) can be segmented. dp[i] is true if some dp[j] is true and s[j..i) is
// a word; only lengths that exist in the dictionary need checking.
// O(n * L * m) time for L distinct word lengths and substring cost m, O(n) space.

bool wordBreak(String s, List<String> wordDict) {
  final words = wordDict.toSet();
  final lengths = {for (final w in wordDict) w.length};
  final dp = List<bool>.filled(s.length + 1, false);
  dp[0] = true; // the empty prefix
  for (var i = 1; i <= s.length; i++) {
    for (final len in lengths) {
      if (len <= i && dp[i - len] && words.contains(s.substring(i - len, i))) {
        dp[i] = true;
        break;
      }
    }
  }
  return dp[s.length];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(wordBreak('leetcode', ['leet', 'code']), true);
  check(wordBreak('applepenapple', ['apple', 'pen']), true); // reuse allowed
  check(wordBreak('catsandog', ['cats', 'dog', 'sand', 'and', 'cat']), false);
  check(wordBreak('aaaaaaa', ['aaaa', 'aaa']), true); // 3 + 4
  check(wordBreak('', ['a']), true);
}
