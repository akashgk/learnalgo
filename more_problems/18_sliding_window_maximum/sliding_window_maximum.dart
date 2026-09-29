// Sliding Window Maximum: the maximum of every window of size k.
// Monotonic deque of indices whose values decrease from front to back. O(n) time, O(k) space.

import 'dart:collection';

List<int> maxSlidingWindow(List<int> nums, int k) {
  final dq = ListQueue<int>(); // indices; nums[dq.first] is the current window's maximum
  final result = <int>[];
  for (var i = 0; i < nums.length; i++) {
    // Drop the front index once it falls out of the window [i - k + 1, i].
    if (dq.isNotEmpty && dq.first <= i - k) dq.removeFirst();
    // A smaller value behind nums[i] can never be a maximum again: nums[i] is newer and larger.
    while (dq.isNotEmpty && nums[dq.last] <= nums[i]) {
      dq.removeLast();
    }
    dq.addLast(i);
    if (i >= k - 1) result.add(nums[dq.first]);
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxSlidingWindow([1, 3, -1, -3, 5, 3, 6, 7], 3), [3, 3, 5, 5, 6, 7]);
  check(maxSlidingWindow([1], 1), [1]);
  check(maxSlidingWindow([9, 8, 7, 6], 2), [9, 8, 7]);
  check(maxSlidingWindow([1, 2, 3, 4], 4), [4]);
  check(maxSlidingWindow([4, 2, 4, 1], 2), [4, 4, 4]);
}
