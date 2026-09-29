// Minimum Characters For Words: smallest multiset of characters that can spell each word
// on its own. For every char, take the maximum count needed by any single word.
// O(n * l) time, O(c) space.

List<String> minimumCharactersForWords(List<String> words) {
  final need = <String, int>{};
  for (final word in words) {
    final counts = <String, int>{};
    for (final ch in word.split('')) {
      counts.update(ch, (v) => v + 1, ifAbsent: () => 1);
    }
    counts.forEach((ch, c) {
      if (c > (need[ch] ?? 0)) need[ch] = c;
    });
  }
  return [
    for (final MapEntry(key: ch, value: c) in need.entries) ...List.filled(c, ch),
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final result = minimumCharactersForWords(['this', 'that', 'did', 'deed', 'them!', 'a'])..sort();
  check(result, ['!', 'a', 'd', 'd', 'e', 'e', 'h', 'i', 'm', 's', 't', 't']);
  check(minimumCharactersForWords([]), []);
}
