// Water Area (trapping rain water). Two pointers moving inward from the lower wall.
// Water above i = min(maxLeft, maxRight) - height[i]. O(n) time, O(1) space.

int waterArea(List<int> heights) {
  var lo = 0, hi = heights.length - 1;
  var leftMax = 0, rightMax = 0, water = 0;
  while (lo < hi) {
    if (heights[lo] < heights[hi]) {
      // The right side has a wall at least this tall, so the left max is the binding limit.
      if (heights[lo] > leftMax) leftMax = heights[lo];
      water += leftMax - heights[lo];
      lo++;
    } else {
      if (heights[hi] > rightMax) rightMax = heights[hi];
      water += rightMax - heights[hi];
      hi--;
    }
  }
  return water;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(waterArea([0, 8, 0, 0, 5, 0, 0, 10, 0, 0, 1, 1, 0, 3]), 48);
  check(waterArea([]), 0);
  check(waterArea([0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]), 6);
  check(waterArea([5, 4, 3]), 0);
}
