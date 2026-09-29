// Square Of Zeroes: does the 0/1 matrix contain a square (side >= 2) whose border is all 0s?
// Precompute, for each cell, how many consecutive 0s extend right and down. Then each candidate
// square's border is checked in O(1). O(n^3) time, O(n^2) space.

bool squareOfZeroes(List<List<int>> matrix) {
  final n = matrix.length;
  final right = List.generate(n, (_) => List<int>.filled(n, 0));
  final down = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var r = n - 1; r >= 0; r--) {
    for (var c = n - 1; c >= 0; c--) {
      if (matrix[r][c] != 0) continue;
      right[r][c] = 1 + (c + 1 < n ? right[r][c + 1] : 0);
      down[r][c] = 1 + (r + 1 < n ? down[r + 1][c] : 0);
    }
  }
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      for (var size = 2; r + size <= n && c + size <= n; size++) {
        final last = size - 1;
        if (right[r][c] >= size &&
            down[r][c] >= size &&
            right[r + last][c] >= size &&
            down[r][c + last] >= size) {
          return true;
        }
      }
    }
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    squareOfZeroes([
      [1, 1, 1, 0, 1, 0],
      [0, 0, 0, 0, 0, 1],
      [0, 1, 1, 1, 0, 1],
      [0, 0, 0, 1, 0, 1],
      [0, 1, 1, 1, 0, 1],
      [0, 0, 0, 0, 0, 1],
    ]),
    true,
  );
  check(squareOfZeroes([[1, 1], [1, 0]]), false);
  check(squareOfZeroes([[0, 0], [0, 0]]), true);
  check(squareOfZeroes([[0, 1, 0], [1, 0, 1], [0, 1, 0]]), false);
}
