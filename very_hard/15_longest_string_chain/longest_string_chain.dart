// Longest String Chain: a chain goes from a string to a string one character shorter obtained
// by removing one character, and so on, using only given strings. Return the longest chain
// (longest string first); a chain needs at least two strings, else return [].
// Sort by length, DP over removals. O(n * m^2 + n log n) time, O(n * m) space.

List<String> longestStringChain(List<String> strings) {
  final sorted = [...strings]..sort((a, b) => a.length.compareTo(b.length));
  final chainLen = <String, int>{};
  final nextInChain = <String, String?>{};
  for (final s in sorted) {
    chainLen[s] = 1;
    nextInChain[s] = null;
    for (var i = 0; i < s.length; i++) {
      final shorter = s.substring(0, i) + s.substring(i + 1);
      final len = chainLen[shorter];
      if (len != null && len + 1 > chainLen[s]!) {
        chainLen[s] = len + 1;
        nextInChain[s] = shorter;
      }
    }
  }
  String? best;
  for (final s in sorted) {
    if (best == null || chainLen[s]! > chainLen[best]!) best = s;
  }
  if (best == null || chainLen[best]! < 2) return [];
  return [for (String? s = best; s != null; s = nextInChain[s]) s];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestStringChain(['abde', 'abc', 'abd', 'abcde', 'ade', 'ae', '1abde', 'abcdef']), [
    'abcdef',
    'abcde',
    'abde',
    'ade',
    'ae',
  ]);
  check(longestStringChain(['abc', 'xyz']), []);
  check(longestStringChain(['a', 'ba', 'bca', 'bdca']), ['bdca', 'bca', 'ba', 'a']);
}
