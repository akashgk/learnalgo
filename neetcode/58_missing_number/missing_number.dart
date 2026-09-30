// Missing Number: n distinct numbers from 0..n, exactly one missing. Find it in O(n) time, O(1) space.
// XOR every index 0..n with every value: each present number cancels with its index, leaving the
// missing one. (The sum formula n(n+1)/2 - sum also works; XOR cannot overflow.)

int missingNumber(List<int> nums) {
  var x = nums.length; // index n has no slot in the loop, so start with it
  for (var i = 0; i < nums.length; i++) {
    x ^= i ^ nums[i];
  }
  return x;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(missingNumber([3, 0, 1]), 2);
  check(missingNumber([0, 1]), 2); // the missing number can be n
  check(missingNumber([9, 6, 4, 2, 3, 5, 7, 0, 1]), 8);
  check(missingNumber([1]), 0);
}
