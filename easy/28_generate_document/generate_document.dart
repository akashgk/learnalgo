// Generate Document: can `document` be built from the available characters (each used once)?
// Count available chars, then consume. O(n + m) time, O(c) space.

bool generateDocument(String characters, String document) {
  final counts = <int, int>{};
  for (final c in characters.codeUnits) {
    counts.update(c, (v) => v + 1, ifAbsent: () => 1);
  }
  for (final c in document.codeUnits) {
    final left = counts[c] ?? 0;
    if (left == 0) return false;
    counts[c] = left - 1;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(generateDocument('Bste!hetsi ogEAxpelrt x ', 'AlgoExpert is the Best!'), true);
  check(generateDocument('A', 'a'), false);
  check(generateDocument('abc', ''), true);
  check(generateDocument('aheaolabbhb', 'hello'), false);
}
