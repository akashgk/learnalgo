// Maximum Sum Submatrix: largest sum of any size x size submatrix.
// 2D prefix sums give each submatrix sum in O(1). O(w * h) time and space.

int maximumSumSubmatrix(List<List<int>> matrix, int size) {
  final rows = matrix.length, cols = matrix[0].length;
  // p[r][c] = sum of matrix[0..r) x [0..c)
  final p = List.generate(rows + 1, (_) => List<int>.filled(cols + 1, 0));
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      p[r + 1][c + 1] = matrix[r][c] + p[r][c + 1] + p[r + 1][c] - p[r][c];
    }
  }
  int? best;
  for (var r = size; r <= rows; r++) {
    for (var c = size; c <= cols; c++) {
      final sum = p[r][c] - p[r - size][c] - p[r][c - size] + p[r - size][c - size];
      if (best == null || sum > best) best = sum;
    }
  }
  return best!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(maximumSumSubmatrix([[5, 3, -1, 5], [-7, 3, 7, 4], [12, 8, 0, 0], [1, -8, -8, 2]], 2), 18);
  check(maximumSumSubmatrix([[-1, -2], [-3, -4]], 1), -1);
  check(maximumSumSubmatrix([[1, 2], [3, 4]], 2), 10);
}
