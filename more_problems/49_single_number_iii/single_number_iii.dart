// Single Number III: every value appears exactly twice except two values that appear once.
// Find those two. XOR everything to get a ^ b, split all numbers by one bit where a and b differ,
// and XOR each group. O(n) time, O(1) space.

List<int> singleNumber(List<int> nums) {
  var both = 0;
  for (final x in nums) {
    both ^= x; // pairs cancel: both == a ^ b, and it is non-zero because a != b
  }
  final lowBit = both & -both; // lowest set bit: a and b differ here
  var a = 0;
  for (final x in nums) {
    if (x & lowBit != 0) a ^= x; // this group contains a (or b) plus whole pairs
  }
  final b = both ^ a;
  return a < b ? [a, b] : [b, a];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(singleNumber([1, 2, 1, 3, 2, 5]), [3, 5]);
  check(singleNumber([-1, 0]), [-1, 0]);
  check(singleNumber([0, 1]), [0, 1]);
  check(singleNumber([4, 7, 4, 9, 9, 12]), [7, 12]);
}
