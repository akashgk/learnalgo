// Search a 2D Matrix (LeetCode 74): each row is sorted and each row starts after the previous row
// ends, so the matrix read row by row is one sorted list. Binary search over indices 0..m*n-1,
// mapping index k to (k ~/ cols, k % cols). O(log(m * n)) time, O(1) space.

bool searchMatrix(List<List<int>> matrix, int target) {
  final rows = matrix.length, cols = matrix[0].length;
  var lo = 0, hi = rows * cols - 1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    final value = matrix[mid ~/ cols][mid % cols];
    if (value == target) return true;
    if (value < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final m = [
    [1, 3, 5, 7],
    [10, 11, 16, 20],
    [23, 30, 34, 60],
  ];
  check(searchMatrix(m, 3), true);
  check(searchMatrix(m, 13), false);
  check(searchMatrix(m, 60), true);
  check(searchMatrix(m, 0), false);
  check(
    searchMatrix([
      [1],
    ], 1),
    true,
  );
}
