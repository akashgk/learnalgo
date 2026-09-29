// Caesar Cipher Encryptor: shift lowercase letters by key, wrapping z -> a.
// O(n) time, O(n) space for the output.

String caesarCipherEncryptor(String string, int key) {
  const a = 97; // 'a'
  final shift = key % 26; // large keys wrap around
  return String.fromCharCodes(string.codeUnits.map((c) => a + (c - a + shift) % 26));
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(caesarCipherEncryptor('xyz', 2), 'zab');
  check(caesarCipherEncryptor('abc', 52), 'abc');
  check(caesarCipherEncryptor('abc', 57), 'fgh');
}
