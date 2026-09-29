// First Non-Repeating Character: index of the first char that occurs exactly once, else -1.
// Two passes with a frequency map. O(n) time, O(1) space (bounded alphabet).

int firstNonRepeatingCharacter(String string) {
  final freq = <int, int>{};
  for (final c in string.codeUnits) {
    freq.update(c, (v) => v + 1, ifAbsent: () => 1);
  }
  for (var i = 0; i < string.length; i++) {
    if (freq[string.codeUnitAt(i)] == 1) return i;
  }
  return -1;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(firstNonRepeatingCharacter('abcdcaf'), 1);
  check(firstNonRepeatingCharacter('faadabcbbebdf'), 6);
  check(firstNonRepeatingCharacter('aabb'), -1);
  check(firstNonRepeatingCharacter(''), -1);
}
