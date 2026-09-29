// Largest Rectangle Under Skyline (histogram). Monotonic increasing stack of indices;
// when a bar is popped, the current index is its right boundary and the new stack top its left.
// O(n) time, O(n) space.

int largestRectangleUnderSkyline(List<int> buildings) {
  final stack = <int>[];
  var best = 0;
  for (var i = 0; i <= buildings.length; i++) {
    final height = i == buildings.length ? 0 : buildings[i]; // sentinel flushes the stack
    while (stack.isNotEmpty && buildings[stack.last] >= height) {
      final h = buildings[stack.removeLast()];
      final left = stack.isEmpty ? -1 : stack.last; // first bar lower than h on the left
      final width = i - left - 1;
      if (h * width > best) best = h * width;
    }
    stack.add(i);
  }
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(largestRectangleUnderSkyline([1, 3, 3, 2, 4, 1, 5, 3, 2]), 9);
  check(largestRectangleUnderSkyline([]), 0);
  check(largestRectangleUnderSkyline([2, 1, 5, 6, 2, 3]), 10);
  check(largestRectangleUnderSkyline([5, 5, 5]), 15);
}
