// Valid IP Addresses: insert three dots into a digit string to make valid IPv4 addresses.
// Each part is 0..255 with no leading zeros. At most 3 * 3 * 3 splits: O(1) time and space
// (input length is at most 12 for any valid answer).

List<String> validIPAddresses(String string) {
  bool valid(String part) {
    if (part.isEmpty || part.length > 3) return false;
    if (part.length > 1 && part.startsWith('0')) return false;
    return int.parse(part) <= 255;
  }

  final result = <String>[];
  final n = string.length;
  for (var i = 1; i < 4 && i < n; i++) {
    final a = string.substring(0, i);
    if (!valid(a)) continue;
    for (var j = i + 1; j < i + 4 && j < n; j++) {
      final b = string.substring(i, j);
      if (!valid(b)) continue;
      for (var k = j + 1; k < j + 4 && k < n; k++) {
        final c = string.substring(j, k), d = string.substring(k);
        if (valid(c) && valid(d)) result.add('$a.$b.$c.$d');
      }
    }
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(validIPAddresses('1921680'), [
    '1.9.216.80', '1.92.16.80', '1.92.168.0', '19.2.16.80', '19.2.168.0',
    '19.21.6.80', '19.21.68.0', '19.216.8.0', '192.1.6.80', '192.1.68.0',
    '192.16.8.0',
  ]);
  check(validIPAddresses('0000'), ['0.0.0.0']);
  check(validIPAddresses('123'), []);
  check(validIPAddresses('2552552551'), ['255.255.25.51', '255.255.255.1']);
  check(validIPAddresses('256256256256'), []);
}
