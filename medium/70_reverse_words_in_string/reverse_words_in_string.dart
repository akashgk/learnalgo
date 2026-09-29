// Reverse Words In String, preserving all whitespace exactly (words and space runs are
// both tokens). Tokenize manually, then reverse the token list. O(n) time and space.

String reverseWordsInString(String string) {
  final tokens = <String>[];
  var start = 0;
  for (var i = 1; i <= string.length; i++) {
    final boundary = i == string.length || (string[i] == ' ') != (string[i - 1] == ' ');
    if (boundary) {
      tokens.add(string.substring(start, i));
      start = i;
    }
  }
  return tokens.reversed.join();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(reverseWordsInString('AlgoExpert is the best!'), 'best! the is AlgoExpert');
  check(reverseWordsInString('whitespaces    4'), '4    whitespaces');
  check(reverseWordsInString(' leading'), 'leading ');
  check(reverseWordsInString(''), '');
}
