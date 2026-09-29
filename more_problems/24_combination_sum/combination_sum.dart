// Combination Sum: all unique combinations of distinct candidates summing to target;
// each candidate may be used any number of times. Backtracking with a start index
// (so each combination is generated in one canonical order). Exponential time.

List<List<int>> combinationSum(List<int> candidates, int target) {
  final c = [...candidates]..sort(); // sorting lets us stop early once a candidate is too big
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start, int remaining) {
    if (remaining == 0) {
      result.add([...path]);
      return;
    }
    for (var i = start; i < c.length; i++) {
      if (c[i] > remaining) break; // every later candidate is even bigger
      path.add(c[i]);
      dfs(i, remaining - c[i]); // i, not i + 1: the same candidate may be reused
      path.removeLast();
    }
  }

  dfs(0, target);
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(combinationSum([2, 3, 6, 7], 7), [
    [2, 2, 3],
    [7],
  ]);
  check(combinationSum([2, 3, 5], 8), [
    [2, 2, 2, 2],
    [2, 3, 3],
    [3, 5],
  ]);
  check(combinationSum([2], 1), []);
  check(combinationSum([1], 2), [
    [1, 1],
  ]);
}
