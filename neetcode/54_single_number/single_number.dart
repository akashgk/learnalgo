// Single Number: every value appears twice except one. Find it in O(n) time and O(1) space.
// XOR everything: x ^ x = 0, x ^ 0 = x, and XOR is commutative, so pairs cancel.

int singleNumber(List<int> nums) => nums.fold(0, (acc, x) => acc ^ x);

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(singleNumber([2, 2, 1]), 1);
  check(singleNumber([4, 1, 2, 1, 2]), 4);
  check(singleNumber([1]), 1);
  check(singleNumber([-3, 7, 7]), -3);
}
