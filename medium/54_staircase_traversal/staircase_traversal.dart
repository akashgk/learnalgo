// Staircase Traversal: ways to climb `height` steps taking 1..maxSteps at a time.
// Sliding-window DP: ways[h] = sum of the previous maxSteps values. O(n) time, O(n) space.

int staircaseTraversal(int height, int maxSteps) {
  final ways = List<int>.filled(height + 1, 0)..[0] = 1;
  var windowSum = 0;
  for (var h = 1; h <= height; h++) {
    windowSum += ways[h - 1]; // step that enters the window
    if (h - maxSteps - 1 >= 0) windowSum -= ways[h - maxSteps - 1]; // step that leaves it
    ways[h] = windowSum;
  }
  return ways[height];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(staircaseTraversal(4, 2), 5);
  check(staircaseTraversal(10, 1), 1);
  check(staircaseTraversal(4, 3), 7);
  check(staircaseTraversal(0, 3), 1);
}
