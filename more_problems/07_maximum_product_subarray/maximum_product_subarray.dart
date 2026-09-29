// Maximum Product Subarray: the largest product of a non-empty contiguous subarray.
// Kadane-style DP tracking both the max and the min product ending here
// (a negative number turns the min into the max). O(n) time, O(1) space.

int maxProduct(List<int> nums) {
  var maxHere = nums[0], minHere = nums[0], best = nums[0];
  for (var i = 1; i < nums.length; i++) {
    final x = nums[i];
    // Candidates for a subarray ending at i: start fresh at x, or extend either extreme.
    final a = x, b = maxHere * x, c = minHere * x;
    maxHere = _max3(a, b, c);
    minHere = _min3(a, b, c);
    if (maxHere > best) best = maxHere;
  }
  return best;
}

int _max3(int a, int b, int c) => a > b ? (a > c ? a : c) : (b > c ? b : c);
int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxProduct([2, 3, -2, 4]), 6);
  check(maxProduct([-2, 0, -1]), 0);
  check(maxProduct([-2, 3, -4]), 24); // two negatives cancel
  check(maxProduct([-2]), -2);
  check(maxProduct([2, -5, -2, -4, 3]), 24); // [-2, -4, 3]
  check(maxProduct([0, 2]), 2);
}
