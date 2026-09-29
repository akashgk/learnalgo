// Maximal Rectangle: largest all-1 rectangle in a binary matrix.
// Treat each row as the floor of a histogram of consecutive 1s above it, and run
// "largest rectangle in histogram" (monotonic stack) on every row. O(rows * cols) time, O(cols) space.

int maximalRectangle(List<String> matrix) {
  if (matrix.isEmpty) return 0;
  final cols = matrix[0].length;
  final heights = List<int>.filled(cols, 0);
  var best = 0;
  for (final row in matrix) {
    for (var c = 0; c < cols; c++) {
      heights[c] = row[c] == '1' ? heights[c] + 1 : 0;
    }
    final area = largestRectangleInHistogram(heights);
    if (area > best) best = area;
  }
  return best;
}

/// For each bar, the widest rectangle using its full height extends to the nearest
/// strictly shorter bar on each side. A bar's right boundary is found when it is popped.
int largestRectangleInHistogram(List<int> heights) {
  final stack = <int>[]; // indices with increasing heights
  var best = 0;
  for (var i = 0; i <= heights.length; i++) {
    final h = i == heights.length ? 0 : heights[i]; // sentinel 0 flushes the stack at the end
    while (stack.isNotEmpty && heights[stack.last] >= h) {
      final height = heights[stack.removeLast()];
      final leftBoundary = stack.isEmpty ? -1 : stack.last; // nearest shorter bar on the left
      final width = i - leftBoundary - 1;
      if (height * width > best) best = height * width;
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
  check(largestRectangleInHistogram([2, 1, 5, 6, 2, 3]), 10);
  check(maximalRectangle(['10100', '10111', '11111', '10010']), 6);
  check(maximalRectangle(['0']), 0);
  check(maximalRectangle(['1']), 1);
  check(maximalRectangle(['111', '111']), 6);
  check(maximalRectangle(['0110', '1111', '0110']), 6); // the middle two columns, all three rows
}
