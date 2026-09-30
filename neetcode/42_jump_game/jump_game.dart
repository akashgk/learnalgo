// Jump Game: nums[i] is the maximum jump length from index i. Can you reach the last index from 0?
// Greedy: track the farthest index reachable so far; if the scan ever passes it, you are stuck.
// O(n) time, O(1) space.

bool canJump(List<int> nums) {
  var farthest = 0;
  for (var i = 0; i < nums.length; i++) {
    if (i > farthest) return false; // index i itself cannot be reached
    final reach = i + nums[i];
    if (reach > farthest) farthest = reach;
    if (farthest >= nums.length - 1) return true;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(canJump([2, 3, 1, 1, 4]), true);
  check(canJump([3, 2, 1, 0, 4]), false); // every path lands on the 0 at index 3
  check(canJump([0]), true); // already at the last index
  check(canJump([0, 1]), false);
  check(canJump([2, 0, 0]), true);
}
