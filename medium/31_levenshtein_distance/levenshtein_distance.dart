// Levenshtein Distance: min insertions, deletions, substitutions to turn str1 into str2.
// Classic 2D DP with a rolling row. O(n * m) time, O(min(n, m)) space.

int levenshteinDistance(String str1, String str2) {
  // Make str2 the shorter string so the row is as small as possible.
  final (long, short) = str1.length >= str2.length ? (str1, str2) : (str2, str1);
  var prev = List<int>.generate(short.length + 1, (j) => j); // "" -> short[0..j)
  for (var i = 1; i <= long.length; i++) {
    final curr = List<int>.filled(short.length + 1, 0)..[0] = i;
    for (var j = 1; j <= short.length; j++) {
      if (long[i - 1] == short[j - 1]) {
        curr[j] = prev[j - 1];
      } else {
        final replace = prev[j - 1], delete = prev[j], insert = curr[j - 1];
        curr[j] = 1 + [replace, delete, insert].reduce((a, b) => a < b ? a : b);
      }
    }
    prev = curr;
  }
  return prev[short.length];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(levenshteinDistance('abc', 'yabd'), 2); // insert y, substitute c -> d
  check(levenshteinDistance('', 'abc'), 3);
  check(levenshteinDistance('kitten', 'sitting'), 3);
  check(levenshteinDistance('same', 'same'), 0);
}
