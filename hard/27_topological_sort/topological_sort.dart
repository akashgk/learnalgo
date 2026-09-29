// Topological Sort: order jobs so every [prereq, job] dependency is respected; [] if a cycle
// makes it impossible. Kahn's algorithm (BFS on in-degree 0). O(j + d) time and space.

import 'dart:collection';

List<int> topologicalSort(List<int> jobs, List<List<int>> deps) {
  final next = {for (final j in jobs) j: <int>[]};
  final inDegree = {for (final j in jobs) j: 0};
  for (final [pre, job] in deps) {
    next[pre]!.add(job);
    inDegree[job] = inDegree[job]! + 1;
  }
  final ready = Queue<int>.of(jobs.where((j) => inDegree[j] == 0));
  final order = <int>[];
  while (ready.isNotEmpty) {
    final job = ready.removeFirst();
    order.add(job);
    for (final dependent in next[job]!) {
      inDegree[dependent] = inDegree[dependent]! - 1;
      if (inDegree[dependent] == 0) ready.add(dependent);
    }
  }
  return order.length == jobs.length ? order : [];
}

bool respects(List<int> order, List<List<int>> deps) {
  final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
  return deps.every((d) => pos[d[0]]! < pos[d[1]]!);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const deps = [
    [1, 2],
    [1, 3],
    [3, 2],
    [4, 2],
    [4, 3],
  ];
  final order = topologicalSort([1, 2, 3, 4], deps);
  check(order.length, 4);
  check(respects(order, deps), true);
  check(
    topologicalSort(
      [1, 2, 3],
      [
        [1, 2],
        [2, 3],
        [3, 1],
      ],
    ),
    [],
  );
  check(topologicalSort([1, 2], []), [1, 2]);
}
