// Pattern Matcher: pattern of 'x' and 'y'; find strings x and y (x != y is not required, but
// y may be empty only if the pattern has no 'y') such that substituting them yields `string`.
// Try every length for x; the length of y follows. O(n^2 + m) time, O(n + m) space.

List<String> patternMatcher(String pattern, String string) {
  if (pattern.isEmpty || pattern.length > string.length) return [];
  // Normalize so the pattern starts with 'x'; remember to swap the answer back.
  final swapped = pattern[0] != 'x';
  final p = swapped ? pattern.split('').map((c) => c == 'x' ? 'y' : 'x').join() : pattern;
  final countX = 'x'.allMatches(p).length, countY = p.length - countX;
  final firstY = p.indexOf('y');

  for (var lenX = 1; lenX * countX <= string.length; lenX++) {
    final rest = string.length - lenX * countX;
    if (countY == 0 && rest != 0) continue;
    if (countY > 0 && rest % countY != 0) continue;
    final lenY = countY == 0 ? 0 : rest ~/ countY;
    final x = string.substring(0, lenX);
    final y = countY == 0 ? '' : string.substring(firstY * lenX, firstY * lenX + lenY);
    final built = p.split('').map((c) => c == 'x' ? x : y).join();
    if (built == string) return swapped ? [y, x] : [x, y];
  }
  return [];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(patternMatcher('xxyxxy', 'gogopowerrangergogopowerranger'), ['go', 'powerranger']);
  check(patternMatcher('yxx', 'yomama'), ['ma', 'yo']);
  check(patternMatcher('xxx', 'abab'), []);
  check(patternMatcher('x', 'anything'), ['anything', '']);
}
