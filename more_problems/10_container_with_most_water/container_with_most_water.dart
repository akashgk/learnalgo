// Container With Most Water: pick two lines that, with the x-axis, hold the most water.
// Two pointers from both ends; always move the shorter line inward. O(n) time, O(1) space.

int maxArea(List<int> height) {
  var lo = 0, hi = height.length - 1, best = 0;
  while (lo < hi) {
    final h = height[lo] < height[hi] ? height[lo] : height[hi];
    final area = h * (hi - lo);
    if (area > best) best = area;
    // The shorter line cannot do better with any closer partner, so discard it.
    if (height[lo] < height[hi]) {
      lo++;
    } else {
      hi--;
    }
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maxArea([1, 8, 6, 2, 5, 4, 8, 3, 7]), 49);
  check(maxArea([1, 1]), 1);
  check(maxArea([4, 3, 2, 1, 4]), 16);
  check(maxArea([1, 2, 1]), 2);
  check(maxArea([5]), 0);
}
