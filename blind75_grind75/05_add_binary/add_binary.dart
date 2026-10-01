// Add Binary: add two binary strings. Grade-school addition from the right with a carry.
// O(max(m, n)) time, O(max(m, n)) space for the result.

String addBinary(String a, String b) {
  final out = <int>[]; // result bits, least significant first
  var i = a.length - 1, j = b.length - 1, carry = 0;
  while (i >= 0 || j >= 0 || carry > 0) {
    var sum = carry;
    if (i >= 0) sum += a.codeUnitAt(i--) - 48;
    if (j >= 0) sum += b.codeUnitAt(j--) - 48;
    out.add(sum & 1); // sum is 0..3: low bit is the digit
    carry = sum >> 1; // high bit is the carry
  }
  return out.reversed.join();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(addBinary('11', '1'), '100');
  check(addBinary('1010', '1011'), '10101');
  check(addBinary('0', '0'), '0');
  check(addBinary('1111', '1'), '10000'); // carry ripples out of the top
  check(addBinary('1', '111'), '1000'); // different lengths
}
