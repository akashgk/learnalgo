// Set Matrix Zeroes: if a cell is 0, set its whole row and column to 0, in place.
// Use the first row and first column as marker storage. O(m*n) time, O(1) extra space.

void setZeroes(List<List<int>> m) {
  final rows = m.length, cols = m[0].length;
  // The first row and column are about to be overwritten with markers,
  // so remember separately whether they themselves must become zero.
  var firstRowZero = false, firstColZero = false;
  for (var c = 0; c < cols; c++) {
    if (m[0][c] == 0) firstRowZero = true;
  }
  for (var r = 0; r < rows; r++) {
    if (m[r][0] == 0) firstColZero = true;
  }
  // Mark: a zero at (r, c) sets m[r][0] and m[0][c] to 0.
  for (var r = 1; r < rows; r++) {
    for (var c = 1; c < cols; c++) {
      if (m[r][c] == 0) {
        m[r][0] = 0;
        m[0][c] = 0;
      }
    }
  }
  // Fill the inner cells from the markers.
  for (var r = 1; r < rows; r++) {
    for (var c = 1; c < cols; c++) {
      if (m[r][0] == 0 || m[0][c] == 0) m[r][c] = 0;
    }
  }
  // Finally the marker row and column themselves.
  if (firstRowZero) {
    for (var c = 0; c < cols; c++) {
      m[0][c] = 0;
    }
  }
  if (firstColZero) {
    for (var r = 0; r < rows; r++) {
      m[r][0] = 0;
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final a = [
    [1, 1, 1],
    [1, 0, 1],
    [1, 1, 1],
  ];
  setZeroes(a);
  check(a, [
    [1, 0, 1],
    [0, 0, 0],
    [1, 0, 1],
  ]);
  final b = [
    [0, 1, 2, 0],
    [3, 4, 5, 2],
    [1, 3, 1, 5],
  ];
  setZeroes(b);
  check(b, [
    [0, 0, 0, 0],
    [0, 4, 5, 0],
    [0, 3, 1, 0],
  ]);
  final c = [
    [1, 2],
    [3, 0],
  ];
  setZeroes(c);
  check(c, [
    [1, 0],
    [0, 0],
  ]);
  final d = [
    [1, 0, 3],
  ];
  setZeroes(d);
  check(d, [
    [0, 0, 0],
  ]);
}
