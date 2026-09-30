// Permutation in String: does s2 contain some permutation of s1 as a substring?
// Fixed-size sliding window of length |s1| with letter counts, plus a counter of how many of the
// 26 letters currently have equal counts. O(|s2|) time, O(1) space.

bool checkInclusion(String s1, String s2) {
  final n = s1.length;
  if (n > s2.length) return false;
  final need = List<int>.filled(26, 0), have = List<int>.filled(26, 0);
  for (var i = 0; i < n; i++) {
    need[s1.codeUnitAt(i) - 97]++;
    have[s2.codeUnitAt(i) - 97]++;
  }
  var matches = 0; // letters whose counts agree between the window and s1
  for (var c = 0; c < 26; c++) {
    if (need[c] == have[c]) matches++;
  }
  for (var right = n; right < s2.length; right++) {
    if (matches == 26) return true;
    // Slide: letter entering on the right, letter leaving on the left.
    matches = _update(need, have, s2.codeUnitAt(right) - 97, 1, matches);
    matches = _update(need, have, s2.codeUnitAt(right - n) - 97, -1, matches);
  }
  return matches == 26;
}

/// Changes have[c] by [delta] and returns the updated number of matching letters.
int _update(List<int> need, List<int> have, int c, int delta, int matches) {
  if (have[c] == need[c]) matches--; // it matched before the change, so it no longer does
  have[c] += delta;
  if (have[c] == need[c]) matches++;
  return matches;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(checkInclusion('ab', 'eidbaooo'), true); // "ba"
  check(checkInclusion('ab', 'eidboaoo'), false);
  check(checkInclusion('adc', 'dcda'), true); // "cda"
  check(checkInclusion('abc', 'ab'), false);
  check(checkInclusion('a', 'a'), true);
}
