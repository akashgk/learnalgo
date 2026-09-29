// Rotate Image: rotate an n x n matrix 90 degrees clockwise, in place.
// Transpose, then reverse each row. O(n^2) time, O(1) extra space.

void rotate(List<List<int>> m) {
  final n = m.length;
  // Transpose: swap across the main diagonal (only the upper triangle, or we undo our own swaps).
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final t = m[i][j];
      m[i][j] = m[j][i];
      m[j][i] = t;
    }
  }
  // Mirror left-right.
  for (final row in m) {
    for (var lo = 0, hi = n - 1; lo < hi; lo++, hi--) {
      final t = row[lo];
      row[lo] = row[hi];
      row[hi] = t;
    }
  }
}

/// Alternative: rotate four cells at a time, layer by layer. Same complexity, one pass.
void rotateLayers(List<List<int>> m) {
  final n = m.length;
  for (var layer = 0; layer < n ~/ 2; layer++) {
    final first = layer, last = n - 1 - layer;
    for (var k = 0; k < last - first; k++) {
      final top = m[first][first + k];
      m[first][first + k] = m[last - k][first]; // left -> top
      m[last - k][first] = m[last][last - k]; // bottom -> left
      m[last][last - k] = m[first + k][last]; // right -> bottom
      m[first + k][last] = top; // top -> right
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  List<List<int>> sample() => [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ];
  final a = sample();
  rotate(a);
  check(a, [
    [7, 4, 1],
    [8, 5, 2],
    [9, 6, 3],
  ]);
  final b = sample();
  rotateLayers(b);
  check(b, a);
  final c = [
    [5, 1, 9, 11],
    [2, 4, 8, 10],
    [13, 3, 6, 7],
    [15, 14, 12, 16],
  ];
  final d = [
    for (final r in c) [...r],
  ];
  rotate(c);
  rotateLayers(d);
  check(c, [
    [15, 13, 2, 5],
    [14, 3, 4, 1],
    [12, 6, 8, 9],
    [16, 7, 10, 11],
  ]);
  check(d, c);
  final one = [
    [1],
  ];
  rotate(one);
  check(one, [
    [1],
  ]);
}
