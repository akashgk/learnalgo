// Run-Length Encoding with runs capped at 9 so the output stays unambiguous
// ("AAAAAAAAAAAA" -> "9A3A"). O(n) time, O(n) space.

String runLengthEncoding(String string) {
  final out = StringBuffer();
  var runLength = 1;
  for (var i = 1; i <= string.length; i++) {
    final atEnd = i == string.length;
    if (atEnd || string[i] != string[i - 1] || runLength == 9) {
      out
        ..write(runLength)
        ..write(string[i - 1]);
      runLength = 0;
    }
    runLength++;
  }
  return out.toString();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(runLengthEncoding('AAAAAAAAAAAAABBCCCCDD'), '9A4A2B4C2D');
  check(runLengthEncoding('aA'), '1a1A');
  check(runLengthEncoding('122333'), '112233');
  check(runLengthEncoding('A'), '1A');
}
