// Strongly Connected Components with Kosaraju's algorithm.
// 1. DFS on the graph, recording vertices by finish time.
// 2. Reverse every edge.
// 3. DFS on the reversed graph in decreasing finish time; each tree is one SCC.
// O(V + E) time, O(V + E) space.

List<List<int>> kosaraju(int n, List<List<int>> edges) {
  final adj = List.generate(n, (_) => <int>[]);
  final radj = List.generate(n, (_) => <int>[]);
  for (final e in edges) {
    adj[e[0]].add(e[1]);
    radj[e[1]].add(e[0]);
  }
  final visited = List<bool>.filled(n, false);
  final order = <int>[]; // vertices in increasing finish time
  void dfs1(int u) {
    visited[u] = true;
    for (final v in adj[u]) {
      if (!visited[v]) dfs1(v);
    }
    order.add(u); // finished: all descendants are done
  }

  for (var u = 0; u < n; u++) {
    if (!visited[u]) dfs1(u);
  }
  visited.fillRange(0, n, false);
  final components = <List<int>>[];
  void dfs2(int u, List<int> component) {
    visited[u] = true;
    component.add(u);
    for (final v in radj[u]) {
      if (!visited[v]) dfs2(v, component);
    }
  }

  for (final u in order.reversed) {
    if (!visited[u]) {
      final component = <int>[];
      dfs2(u, component);
      components.add(component..sort());
    }
  }
  return components;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // 0 -> 1 -> 2 -> 0 is a cycle; 2 -> 3; 3 -> 4 -> 5 -> 3 is another cycle; 6 alone.
  final edges = [
    [0, 1],
    [1, 2],
    [2, 0],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 3],
    [6, 5],
  ];
  final sccs = kosaraju(7, edges)..sort((a, b) => a.first.compareTo(b.first));
  check(sccs, [
    [0, 1, 2],
    [3, 4, 5],
    [6],
  ]);
  check(
    kosaraju(3, [
      [0, 1],
      [1, 2],
    ]).length,
    3,
  ); // a DAG: every vertex is its own SCC
  check(
    kosaraju(2, [
      [0, 1],
      [1, 0],
    ]),
    [
      [0, 1],
    ],
  );
}
