// Longest Repeating Character Replacement: replace at most k characters (uppercase A-Z)
// to get the longest run of one letter. Sliding window: a window is valid when
// windowLength - (count of its most frequent letter) <= k. O(n) time, O(1) space (26 counters).

int characterReplacement(String s, int k) {
  final count = List<int>.filled(26, 0);
  var left = 0, maxFreq = 0, best = 0;
  for (var right = 0; right < s.length; right++) {
    final c = s.codeUnitAt(right) - 65;
    count[c]++;
    if (count[c] > maxFreq) maxFreq = count[c];
    // Too many letters to replace: slide the window by one (it never shrinks below best).
    if (right - left + 1 - maxFreq > k) {
      count[s.codeUnitAt(left) - 65]--;
      left++;
    }
    if (right - left + 1 > best) best = right - left + 1;
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(characterReplacement('ABAB', 2), 4);
  check(characterReplacement('AABABBA', 1), 4); // "AABA" -> "AAAA" or "ABBB"
  check(characterReplacement('AAAA', 0), 4);
  check(characterReplacement('ABCDE', 1), 2);
  check(characterReplacement('', 3), 0);
  check(characterReplacement('ABBB', 0), 3);
}
