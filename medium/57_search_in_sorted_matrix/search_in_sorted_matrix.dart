// Search In Sorted Matrix: rows and columns sorted ascending. Start at the top-right corner:
// too big -> move left, too small -> move down. O(n + m) time, O(1) space.

List<int> searchInSortedMatrix(List<List<int>> matrix, int target) {
  var row = 0, col = matrix[0].length - 1;
  while (row < matrix.length && col >= 0) {
    final value = matrix[row][col];
    if (value == target) return [row, col];
    if (value > target) {
      col--; // everything below in this column is even bigger
    } else {
      row++; // everything left in this row is even smaller
    }
  }
  return [-1, -1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const m = [
    [1, 4, 7, 12, 15, 1000],
    [2, 5, 19, 31, 32, 1001],
    [3, 8, 24, 33, 35, 1002],
    [40, 41, 42, 44, 45, 1003],
    [99, 100, 103, 106, 128, 1004],
  ];
  check(searchInSortedMatrix(m, 44), [3, 3]);
  check(searchInSortedMatrix(m, 1), [0, 0]);
  check(searchInSortedMatrix(m, 1004), [4, 5]);
  check(searchInSortedMatrix(m, 43), [-1, -1]);
}
