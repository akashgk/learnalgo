// Spiral Traverse: clockwise from the top-left. Shrink four boundaries after each perimeter.
// O(n) time for n cells, O(n) output.

List<int> spiralTraverse(List<List<int>> matrix) {
  final out = <int>[];
  if (matrix.isEmpty) return out;
  var top = 0, bottom = matrix.length - 1, left = 0, right = matrix[0].length - 1;
  while (top <= bottom && left <= right) {
    for (var c = left; c <= right; c++) {
      out.add(matrix[top][c]);
    }
    for (var r = top + 1; r <= bottom; r++) {
      out.add(matrix[r][right]);
    }
    // Guards stop a single remaining row/column from being traversed twice.
    if (top < bottom) {
      for (var c = right - 1; c >= left; c--) {
        out.add(matrix[bottom][c]);
      }
    }
    if (left < right) {
      for (var r = bottom - 1; r > top; r--) {
        out.add(matrix[r][left]);
      }
    }
    top++;
    bottom--;
    left++;
    right--;
  }
  return out;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    spiralTraverse([
      [1, 2, 3, 4],
      [12, 13, 14, 5],
      [11, 16, 15, 6],
      [10, 9, 8, 7],
    ]),
    List.generate(16, (i) => i + 1),
  );
  check(spiralTraverse([[1, 2, 3], [8, 9, 4], [7, 6, 5]]), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
  check(spiralTraverse([[1, 2, 3, 4]]), [1, 2, 3, 4]);
  check(spiralTraverse([[1], [2], [3]]), [1, 2, 3]);
  check(spiralTraverse([[1, 2], [6, 3], [5, 4]]), [1, 2, 3, 4, 5, 6]);
}
