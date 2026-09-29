// Missing Numbers: array holds distinct numbers from 1..n+2 with exactly two missing.
// XOR approach: xor of all = a ^ b; split by a set bit. O(n) time, O(1) space.

List<int> missingNumbers(List<int> nums) {
  final n = nums.length + 2;
  var xorAll = 0;
  for (var v = 1; v <= n; v++) {
    xorAll ^= v;
  }
  for (final x in nums) {
    xorAll ^= x;
  }
  // xorAll == a ^ b, and a != b so some bit differs. Take the lowest set bit.
  final bit = xorAll & -xorAll;
  var a = 0, b = 0;
  for (var v = 1; v <= n; v++) {
    if (v & bit != 0) {
      a ^= v;
    } else {
      b ^= v;
    }
  }
  for (final x in nums) {
    if (x & bit != 0) {
      a ^= x;
    } else {
      b ^= x;
    }
  }
  return a < b ? [a, b] : [b, a];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(missingNumbers([1, 4, 3]), [2, 5]);
  check(missingNumbers([]), [1, 2]);
  check(missingNumbers([4, 5, 1, 3]), [2, 6]);
}
