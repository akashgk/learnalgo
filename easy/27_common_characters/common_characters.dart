// Common Characters: characters present in every string. Intersect sets, starting from the
// shortest string. O(n * m) time, O(m) space (m = length of the shortest/longest string).

List<String> commonCharacters(List<String> strings) {
  final shortest = strings.reduce((a, b) => a.length <= b.length ? a : b);
  var common = shortest.split('').toSet();
  for (final s in strings) {
    common = common.intersection(s.split('').toSet());
  }
  return common.toList()..sort();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(commonCharacters(['abc', 'bcd', 'cbaccd']), ['b', 'c']);
  check(commonCharacters(['a', 'b', 'c']), []);
  check(commonCharacters(['abcde', 'aa', 'foobar', 'foobaz', 'and this is a string', 'aaaaaaaa', 'eeeeee']), []);
}
