// Subsets II: all subsets of an array that may contain duplicates, without duplicate subsets.
// Sort, then backtrack; at each depth skip a value equal to the previous choice at the same depth.
// O(n * 2^n) time, O(n) recursion space (excluding output).

List<List<int>> subsetsWithDup(List<int> nums) {
  final a = [...nums]..sort();
  final result = <List<int>>[];
  final path = <int>[];
  void dfs(int start) {
    result.add([...path]); // every node of the recursion tree is a subset
    for (var i = start; i < a.length; i++) {
      // Choosing a[i] here after skipping an equal a[i - 1] at this same depth repeats a subset.
      if (i > start && a[i] == a[i - 1]) continue;
      path.add(a[i]);
      dfs(i + 1);
      path.removeLast();
    }
  }

  dfs(0);
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(subsetsWithDup([1, 2, 2]), [
    <int>[],
    [1],
    [1, 2],
    [1, 2, 2],
    [2],
    [2, 2],
  ]);
  check(subsetsWithDup([0]), [
    <int>[],
    [0],
  ]);
  check(subsetsWithDup([2, 2, 2]).length, 4); // [], [2], [2,2], [2,2,2]
  check(subsetsWithDup([4, 4, 4, 1, 4]).length, 10); // 2 choices for 1 times 5 counts of 4
}
