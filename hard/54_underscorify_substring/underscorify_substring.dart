// Underscorify Substring: wrap every occurrence of `substring` in underscores, merging
// overlapping or adjacent occurrences into one wrapped region.
// Find occurrence intervals, merge, then build. O(n * m) time, O(n) space.

String underscorifySubstring(String string, String substring) {
  final intervals = <List<int>>[];
  var from = 0;
  while (true) {
    final idx = string.indexOf(substring, from);
    if (idx == -1) break;
    final end = idx + substring.length;
    if (intervals.isNotEmpty && idx <= intervals.last[1]) {
      intervals.last[1] = end; // overlapping or touching: extend
    } else {
      intervals.add([idx, end]);
    }
    from = idx + 1; // allow overlapping matches
  }
  final out = StringBuffer();
  var pos = 0;
  for (final [s, e] in intervals) {
    out
      ..write(string.substring(pos, s))
      ..write('_')
      ..write(string.substring(s, e))
      ..write('_');
    pos = e;
  }
  out.write(string.substring(pos));
  return out.toString();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    underscorifySubstring('testthis is a testtest to see if testestest it works', 'test'),
    '_test_this is a _testtest_ to see if _testestest_ it works',
  );
  check(underscorifySubstring('abc', 'x'), 'abc');
  check(underscorifySubstring('aaa', 'a'), '_aaa_');
}
