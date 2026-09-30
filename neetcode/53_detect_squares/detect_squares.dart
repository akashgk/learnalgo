// Detect Squares: add(point) stores points (duplicates allowed); count(point) returns how many ways
// to choose three stored points forming an axis-aligned square of positive area with the query.
// For each stored point that could be the DIAGONAL opposite corner, the other two corners are
// fixed: multiply their counts. add O(1), count O(number of distinct points).

class DetectSquares {
  final _count = <(int, int), int>{};

  void add(List<int> point) {
    final p = (point[0], point[1]);
    _count[p] = (_count[p] ?? 0) + 1;
  }

  int count(List<int> point) {
    final x = point[0], y = point[1];
    var total = 0;
    _count.forEach((p, c) {
      final (px, py) = p;
      // A diagonal corner must differ in both coordinates by the same nonzero amount.
      if ((px - x).abs() != (py - y).abs() || px == x) return;
      total += c * (_count[(x, py)] ?? 0) * (_count[(px, y)] ?? 0);
    });
    return total;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final ds = DetectSquares()
    ..add([3, 10])
    ..add([11, 2])
    ..add([3, 2]);
  check(ds.count([11, 10]), 1);
  check(ds.count([14, 8]), 0);
  ds.add([11, 2]); // duplicate point: two choices for that corner
  check(ds.count([11, 10]), 2);
  final squares = DetectSquares()
    ..add([0, 0])
    ..add([1, 1])
    ..add([0, 1]);
  check(squares.count([1, 0]), 1);
  check(squares.count([0, 0]), 0); // (1, 0) was queried, not added
}
