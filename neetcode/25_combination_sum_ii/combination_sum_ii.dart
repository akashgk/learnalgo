// Combination Sum II: candidates may contain duplicates; each element may be used at most once.
// Return all unique combinations that sum to target.
// Sort, backtrack with a start index, recurse with i + 1 (no reuse), and skip equal values at the
// same depth (no duplicate combinations). Exponential time, O(n) recursion space.

List<List<int>> combinationSum2(List<int> candidates, int target) {
  final c = [...candidates]..sort();
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start, int remaining) {
    if (remaining == 0) {
      result.add([...path]);
      return;
    }
    for (var i = start; i < c.length; i++) {
      if (i > start && c[i] == c[i - 1]) continue; // same value already tried at this depth
      if (c[i] > remaining) break; // sorted: every later value is too big as well
      path.add(c[i]);
      dfs(i + 1, remaining - c[i]); // i + 1: each element used at most once
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
  check(combinationSum2([10, 1, 2, 7, 6, 1, 5], 8), [
    [1, 1, 6],
    [1, 2, 5],
    [1, 7],
    [2, 6],
  ]);
  check(combinationSum2([2, 5, 2, 1, 2], 5), [
    [1, 2, 2],
    [5],
  ]);
  check(combinationSum2([2], 1), []);
  check(combinationSum2([1, 1, 1], 2), [
    [1, 1],
  ]);
}
