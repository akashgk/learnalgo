// Interweaving Strings: can `three` be formed by interleaving `one` and `two`, keeping each
// one's character order? 2D DP (rolling row). O(n * m) time, O(m) space.

bool interweavingStrings(String one, String two, String three) {
  final n = one.length, m = two.length;
  if (n + m != three.length) return false;
  // ok[j] = can one[0..i) and two[0..j) form three[0..i+j)
  final ok = List<bool>.filled(m + 1, false)..[0] = true;
  for (var j = 1; j <= m; j++) {
    ok[j] = ok[j - 1] && two[j - 1] == three[j - 1];
  }
  for (var i = 1; i <= n; i++) {
    ok[0] = ok[0] && one[i - 1] == three[i - 1];
    for (var j = 1; j <= m; j++) {
      final k = i + j - 1;
      ok[j] = (ok[j] && one[i - 1] == three[k]) || (ok[j - 1] && two[j - 1] == three[k]);
    }
  }
  return ok[m];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(interweavingStrings('algoexpert', 'your-dream-job', 'your-algodream-expertjob'), true);
  check(interweavingStrings('aabcc', 'dbbca', 'aadbbcbcac'), true);
  check(interweavingStrings('aabcc', 'dbbca', 'aadbbbaccc'), false);
  check(interweavingStrings('', '', ''), true);
  check(interweavingStrings('a', '', 'b'), false);
}
