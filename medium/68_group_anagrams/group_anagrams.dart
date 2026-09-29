// Group Anagrams: key each word by its sorted letters. O(w * n log n) time, O(w * n) space.
// (A 26-count signature key gives O(w * n).)

List<List<String>> groupAnagrams(List<String> words) {
  final groups = <String, List<String>>{};
  for (final word in words) {
    final key = String.fromCharCodes(word.codeUnits.toList()..sort());
    (groups[key] ??= []).add(word);
  }
  return groups.values.toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(groupAnagrams(['yo', 'act', 'flop', 'tac', 'foo', 'cat', 'oy', 'olfp']), [
    ['yo', 'oy'],
    ['act', 'tac', 'cat'],
    ['flop', 'olfp'],
    ['foo'],
  ]);
  check(groupAnagrams([]), []);
}
