// Find All Anagrams in a String: start indices of every substring of s that is an anagram of p
// (lowercase letters). Fixed-size sliding window with a count of letters whose counts match.
// O(|s| + |p|) time, O(1) space.

List<int> findAnagrams(String s, String p) {
  final n = p.length, result = <int>[];
  if (n > s.length) return result;
  final need = List<int>.filled(26, 0), have = List<int>.filled(26, 0);
  for (var i = 0; i < n; i++) {
    need[p.codeUnitAt(i) - 97]++;
    have[s.codeUnitAt(i) - 97]++;
  }
  var matches = 0; // how many of the 26 letters have equal counts in window and p
  for (var c = 0; c < 26; c++) {
    if (need[c] == have[c]) matches++;
  }
  if (matches == 26) result.add(0);
  for (var right = n; right < s.length; right++) {
    matches = _update(need, have, s.codeUnitAt(right) - 97, 1, matches); // enters
    matches = _update(need, have, s.codeUnitAt(right - n) - 97, -1, matches); // leaves
    if (matches == 26) result.add(right - n + 1);
  }
  return result;
}

int _update(List<int> need, List<int> have, int c, int delta, int matches) {
  if (have[c] == need[c]) matches--;
  have[c] += delta;
  if (have[c] == need[c]) matches++;
  return matches;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(findAnagrams('cbaebabacd', 'abc'), [0, 6]);
  check(findAnagrams('abab', 'ab'), [0, 1, 2]);
  check(findAnagrams('a', 'ab'), []);
  check(findAnagrams('aaaa', 'aa'), [0, 1, 2]);
}
