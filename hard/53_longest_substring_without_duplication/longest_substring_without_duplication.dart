// Longest Substring Without Duplication. Sliding window with last-seen index per character.
// O(n) time, O(min(n, alphabet)) space.

String longestSubstringWithoutDuplication(String string) {
  final lastSeen = <int, int>{};
  var start = 0, bestStart = 0, bestLen = 0;
  for (var i = 0; i < string.length; i++) {
    final c = string.codeUnitAt(i);
    final prev = lastSeen[c];
    if (prev != null && prev >= start) start = prev + 1; // jump past the duplicate
    lastSeen[c] = i;
    if (i - start + 1 > bestLen) {
      bestLen = i - start + 1;
      bestStart = start;
    }
  }
  return string.substring(bestStart, bestStart + bestLen);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestSubstringWithoutDuplication('clementisacap'), 'mentisac');
  check(longestSubstringWithoutDuplication('abba'), 'ab');
  check(longestSubstringWithoutDuplication('a'), 'a');
  check(longestSubstringWithoutDuplication(''), '');
}
