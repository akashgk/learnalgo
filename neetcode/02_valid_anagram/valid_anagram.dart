// Valid Anagram: is t a rearrangement of s?
// Count characters up for s and down for t; every count must end at zero. O(n) time, O(k) space
// (k = alphabet size; 26 for lowercase letters).

bool isAnagram(String s, String t) {
  if (s.length != t.length) return false;
  final count = <int, int>{}; // code unit -> net count (a map also handles non-lowercase input)
  for (var i = 0; i < s.length; i++) {
    count[s.codeUnitAt(i)] = (count[s.codeUnitAt(i)] ?? 0) + 1;
    count[t.codeUnitAt(i)] = (count[t.codeUnitAt(i)] ?? 0) - 1;
  }
  return count.values.every((c) => c == 0);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isAnagram('anagram', 'nagaram'), true);
  check(isAnagram('rat', 'car'), false);
  check(isAnagram('a', 'ab'), false);
  check(isAnagram('', ''), true);
  check(isAnagram('aacc', 'ccac'), false); // same letters, different counts
}
