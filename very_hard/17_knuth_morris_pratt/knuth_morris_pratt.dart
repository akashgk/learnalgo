// Knuth-Morris-Pratt: does `substring` occur in `string`? O(n + m) time, O(m) space.
// lps[i] = length of the longest proper prefix of pattern[0..i] that is also a suffix of it.

bool knuthMorrisPrattAlgorithm(String string, String substring) {
  if (substring.isEmpty) return true;
  final lps = _buildLps(substring);
  var j = 0; // characters of the pattern matched so far
  for (var i = 0; i < string.length; i++) {
    while (j > 0 && string[i] != substring[j]) {
      j = lps[j - 1]; // fall back without moving i
    }
    if (string[i] == substring[j]) j++;
    if (j == substring.length) return true;
  }
  return false;
}

List<int> _buildLps(String p) {
  final lps = List<int>.filled(p.length, 0);
  var len = 0;
  for (var i = 1; i < p.length; i++) {
    while (len > 0 && p[i] != p[len]) {
      len = lps[len - 1];
    }
    if (p[i] == p[len]) len++;
    lps[i] = len;
  }
  return lps;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(knuthMorrisPrattAlgorithm('aefoaefcdaefcdaed', 'aefcdaed'), true);
  check(knuthMorrisPrattAlgorithm('testwhere', 'testx'), false);
  check(knuthMorrisPrattAlgorithm('aaaaaaaab', 'aaab'), true);
  check(_buildLps('aefcdaed'), [0, 0, 0, 0, 0, 1, 2, 0]);
  check(_buildLps('aabaaab'), [0, 1, 0, 1, 2, 2, 3]);
}
