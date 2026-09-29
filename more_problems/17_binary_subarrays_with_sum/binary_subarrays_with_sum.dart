// Binary Subarrays With Sum: count subarrays of a 0/1 array with sum exactly goal.
// "exactly(goal) = atMost(goal) - atMost(goal - 1)", each counted with a sliding window.
// O(n) time, O(1) space. (The prefix-sum hash map also works, with O(n) space.)

int numSubarraysWithSum(List<int> nums, int goal) => _atMost(nums, goal) - _atMost(nums, goal - 1);

/// Number of subarrays whose sum is <= [goal]. Valid because all values are non-negative,
/// so extending a window never decreases its sum.
int _atMost(List<int> nums, int goal) {
  if (goal < 0) return 0;
  var left = 0, sum = 0, count = 0;
  for (var right = 0; right < nums.length; right++) {
    sum += nums[right];
    while (sum > goal) {
      sum -= nums[left++];
    }
    // Every subarray ending at right and starting in [left, right] is valid.
    count += right - left + 1;
  }
  return count;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(numSubarraysWithSum([1, 0, 1, 0, 1], 2), 4);
  check(numSubarraysWithSum([0, 0, 0, 0, 0], 0), 15); // 5 * 6 / 2
  check(numSubarraysWithSum([1, 1, 1], 2), 2);
  check(numSubarraysWithSum([1, 0, 1], 3), 0);
  check(numSubarraysWithSum([0, 1, 0], 1), 4);
}
