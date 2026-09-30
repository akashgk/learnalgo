// Decode Ways: letters A-Z are encoded as 1-26. Count the ways to decode a digit string.
// dp[i] = ways to decode the first i digits = (last digit alone, if not '0') dp[i-1]
//       + (last two digits together, if 10..26) dp[i-2]. O(n) time, O(1) space.

int numDecodings(String s) {
  var twoBack = 1, oneBack = s.isEmpty || s[0] == '0' ? 0 : 1; // dp[0] = 1 (empty), dp[1]
  for (var i = 2; i <= s.length; i++) {
    var here = 0;
    if (s[i - 1] != '0') here += oneBack; // single digit 1..9
    final two = int.parse(s.substring(i - 2, i));
    if (two >= 10 && two <= 26) here += twoBack; // two digits 10..26 (no leading zero)
    twoBack = oneBack;
    oneBack = here;
  }
  return s.isEmpty ? 0 : oneBack;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(numDecodings('12'), 2); // AB, L
  check(numDecodings('226'), 3); // BBF, BZ, VF
  check(numDecodings('06'), 0); // leading zero
  check(numDecodings('10'), 1); // J only
  check(numDecodings('100'), 0); // "00" cannot be decoded
  check(numDecodings('11106'), 2); // AAJF, KJF
  check(numDecodings('27'), 1); // 27 > 26
}
