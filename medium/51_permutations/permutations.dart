// Permutations of distinct integers. Backtracking by swapping in place.
// O(n * n!) time (n! permutations, O(n) to copy each), O(n * n!) output space.

List<List<int>> getPermutations(List<int> array) {
  final result = <List<int>>[];
  final a = [...array];

  void permute(int i) {
    if (i == a.length) {
      if (a.isNotEmpty) result.add([...a]);
      return;
    }
    for (var j = i; j < a.length; j++) {
      _swap(a, i, j); // choose a[j] for position i
      permute(i + 1);
      _swap(a, i, j); // undo (backtrack)
    }
  }

  permute(0);
  return result;
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(getPermutations([1, 2, 3]), [
    [1, 2, 3],
    [1, 3, 2],
    [2, 1, 3],
    [2, 3, 1],
    [3, 2, 1],
    [3, 1, 2],
  ]);
  check(getPermutations([]), []);
  check(getPermutations([1, 2, 3, 4, 5]).length, 120);
}
