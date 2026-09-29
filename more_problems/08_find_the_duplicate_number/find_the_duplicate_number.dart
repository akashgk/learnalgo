// Find the Duplicate Number: n + 1 integers in [1, n], exactly one value repeated (possibly many times).
// Without modifying the array and in O(1) extra space: treat i -> nums[i] as a linked list
// and find the cycle entrance with Floyd's tortoise and hare. O(n) time, O(1) space.

int findDuplicate(List<int> nums) {
  // Phase 1: move slow one step and fast two steps until they meet inside the cycle.
  var slow = nums[0], fast = nums[nums[0]];
  while (slow != fast) {
    slow = nums[slow];
    fast = nums[nums[fast]];
  }
  // Phase 2: restart one pointer from the head; moving both one step, they meet at the entrance.
  slow = 0;
  while (slow != fast) {
    slow = nums[slow];
    fast = nums[fast];
  }
  return slow;
}

/// Alternative: binary search on the value, counting how many elements are <= mid.
/// O(n log n) time, O(1) space, also read-only.
int findDuplicateByCounting(List<int> nums) {
  var lo = 1, hi = nums.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    final count = nums.where((x) => x <= mid).length;
    // With no duplicate in [1, mid], exactly mid values would be <= mid.
    if (count > mid) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  for (final f in [findDuplicate, findDuplicateByCounting]) {
    check(f([1, 3, 4, 2, 2]), 2);
    check(f([3, 1, 3, 4, 2]), 3);
    check(f([3, 3, 3, 3, 3]), 3);
    check(f([1, 1]), 1);
    check(f([2, 5, 9, 6, 9, 3, 8, 9, 7, 1]), 9);
  }
}
