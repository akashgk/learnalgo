// Task Assignment: 2k tasks, k workers, each does 2 tasks in parallel with others.
// Minimize the slowest worker: pair shortest with longest. Return index pairs.
// O(n log n) time, O(n) space.

List<List<int>> taskAssignment(int k, List<int> tasks) {
  final order = List<int>.generate(tasks.length, (i) => i)
    ..sort((a, b) => tasks[a].compareTo(tasks[b])); // sort indices, keep originals
  return [
    for (var i = 0; i < k; i++) [order[i], order[tasks.length - 1 - i]],
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final result = taskAssignment(3, [1, 3, 5, 3, 1, 4]);
  final tasks = [1, 3, 5, 3, 1, 4];
  final maxPair = result.map((p) => tasks[p[0]] + tasks[p[1]]).reduce((a, b) => a > b ? a : b);
  check(maxPair, 6);
  check(result.expand((p) => p).toSet().length, 6); // every task used exactly once
}
