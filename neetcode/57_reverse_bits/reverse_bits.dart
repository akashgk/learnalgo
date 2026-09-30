// Reverse Bits of a 32-bit unsigned integer (given and returned as a non-negative int).
// Shift the lowest bit of n into the result 32 times. O(32) time.

int reverseBits(int n) {
  var result = 0;
  for (var i = 0; i < 32; i++) {
    result = (result << 1) | (n & 1); // append n's lowest bit
    n >>= 1;
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(reverseBits(43261596), 964176192); // 00000010100101000001111010011100 reversed
  check(reverseBits(4294967293), 3221225471); // 11111111111111111111111111111101 reversed
  check(reverseBits(1), 2147483648); // bit 0 becomes bit 31
  check(reverseBits(0), 0);
}
