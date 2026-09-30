// Encode and Decode Strings: turn a list of arbitrary strings into one string and back.
// Length-prefix framing: each string is written as "<length>#<string>". The decoder reads the
// length first, so '#' (or any character) inside the strings is harmless. O(total length) both ways.

String encode(List<String> strs) {
  final out = StringBuffer();
  for (final s in strs) {
    out
      ..write(s.length)
      ..write('#')
      ..write(s);
  }
  return out.toString();
}

List<String> decode(String data) {
  final result = <String>[];
  var i = 0;
  while (i < data.length) {
    final hash = data.indexOf('#', i); // the first '#' after i ends the length field
    final length = int.parse(data.substring(i, hash));
    final start = hash + 1;
    result.add(data.substring(start, start + length));
    i = start + length; // jump over the payload without inspecting it
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final cases = [
    ['neet', 'code', 'love', 'you'],
    ['we', 'say', ':', 'yes'],
    ['a#b', '12#', '#', ''], // separators and digits inside the strings
    <String>[],
    [''],
  ];
  for (final c in cases) {
    check(decode(encode(c)), c);
  }
  check(encode(['a#b', '']), '3#a#b0#');
}
