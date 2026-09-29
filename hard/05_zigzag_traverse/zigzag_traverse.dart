// Zigzag Traverse: start top-left, go down, then zigzag along anti-diagonals.
// Iterate diagonals d = r + c; alternate direction per diagonal. O(n) time, O(n) output.

List<int> zigzagTraverse(List<List<int>> array) {
  final out = <int>[];
  if (array.isEmpty) return out;
  final rows = array.length, cols = array[0].length;
  for (var d = 0; d < rows + cols - 1; d++) {
    // Rows on diagonal d range over [rLo, rHi].
    final rLo = d - (cols - 1) > 0 ? d - (cols - 1) : 0;
    final rHi = d < rows - 1 ? d : rows - 1;
    if (d.isEven) {
      // even diagonals go down-left: increasing row
      for (var r = rLo; r <= rHi; r++) {
        out.add(array[r][d - r]);
      }
    } else {
      // odd diagonals go up-right: decreasing row
      for (var r = rHi; r >= rLo; r--) {
        out.add(array[r][d - r]);
      }
    }
  }
  return out;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    zigzagTraverse([
      [1, 3, 4, 10],
      [2, 5, 9, 11],
      [6, 8, 12, 15],
      [7, 13, 14, 16],
    ]),
    List.generate(16, (i) => i + 1),
  );
  check(
    zigzagTraverse([
      [1, 3],
      [2, 4],
      [5, 7],
      [6, 8],
    ]),
    [1, 2, 3, 4, 5, 6, 7, 8],
  );
  check(
    zigzagTraverse([
      [1, 2, 3],
    ]),
    [1, 2, 3],
  );
  check(
    zigzagTraverse([
      [1],
      [2],
      [3],
    ]),
    [1, 2, 3],
  );
}
