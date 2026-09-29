// Non-Attacking Queens: number of ways to place n queens on an n x n board with no attacks.
// Backtracking row by row with bitmasks for columns and both diagonals.
// O(n!) time (pruned heavily), O(n) space.

int nonAttackingQueens(int n) {
  final full = (1 << n) - 1;
  int place(int cols, int diag, int antiDiag) {
    if (cols == full) return 1;
    var count = 0;
    // Free positions in this row: not attacked by column or either diagonal.
    var free = full & ~(cols | diag | antiDiag);
    while (free != 0) {
      final bit = free & -free; // lowest free column
      free -= bit;
      // Diagonals shift by one column per row moved down.
      count += place(cols | bit, ((diag | bit) << 1) & full, (antiDiag | bit) >> 1);
    }
    return count;
  }

  return place(0, 0, 0);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check([for (var n = 1; n <= 8; n++) nonAttackingQueens(n)], [1, 0, 0, 2, 10, 4, 40, 92]);
}
