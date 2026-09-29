// Transpose Matrix
// result[c][r] = matrix[r][c]. O(w * h) time and space.

List<List<int>> transposeMatrix(List<List<int>> matrix) {
  if (matrix.isEmpty) return [];
  final rows = matrix.length, cols = matrix[0].length;
  return List.generate(cols, (c) => List.generate(rows, (r) => matrix[r][c]));
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(transposeMatrix([[1, 2], [3, 4], [5, 6]]), [[1, 3, 5], [2, 4, 6]]);
  check(transposeMatrix([[1, 2, 3]]), [[1], [2], [3]]);
  check(transposeMatrix([[1]]), [[1]]);
}
