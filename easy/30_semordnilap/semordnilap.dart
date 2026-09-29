// Semordnilap: pairs of distinct words where one is the reverse of the other.
// Hash set lookups; remove matched words so each pair is reported once. O(n * m) time, O(n * m) space.

List<List<String>> semordnilap(List<String> words) {
  final remaining = words.toSet();
  final pairs = <List<String>>[];
  for (final word in words) {
    final reversed = word.split('').reversed.join();
    if (reversed != word && remaining.contains(word) && remaining.contains(reversed)) {
      pairs.add([word, reversed]);
      remaining
        ..remove(word)
        ..remove(reversed);
    }
  }
  return pairs;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(semordnilap(['diaper', 'abc', 'test', 'cba', 'repaid']), [
    ['diaper', 'repaid'],
    ['abc', 'cba'],
  ]);
  check(semordnilap(['aaa', 'bbb']), []); // palindromes pair with themselves only, not allowed
  check(semordnilap(['dog', 'god', 'dog']), [
    ['dog', 'god'],
  ]);
}
