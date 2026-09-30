// Graph Valid Tree: do n nodes (0..n-1) and these undirected edges form a tree?
// A graph is a tree iff it has exactly n - 1 edges AND no cycle (equivalently: n - 1 edges and
// connected). Union-find detects a cycle on the first edge joining two already-connected nodes.
// O(n + E * alpha(n)) time, O(n) space.

bool validTree(int n, List<List<int>> edges) {
  if (edges.length != n - 1) return false; // too few: disconnected; too many: a cycle
  final parent = List<int>.generate(n, (i) => i);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  for (final e in edges) {
    final a = find(e[0]), b = find(e[1]);
    if (a == b) return false; // cycle
    parent[a] = b;
  }
  // n - 1 edges and no cycle: the graph is connected, so it is a tree.
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    validTree(5, [
      [0, 1],
      [0, 2],
      [0, 3],
      [1, 4],
    ]),
    true,
  );
  check(
    validTree(5, [
      [0, 1],
      [1, 2],
      [2, 3],
      [1, 3],
      [1, 4],
    ]),
    false,
  ); // 5 edges
  check(
    validTree(4, [
      [0, 1],
      [2, 3],
      [1, 0],
    ]),
    false,
  ); // right count, but a cycle (0-1 twice) and 2-3 disconnected
  check(validTree(1, []), true);
  check(validTree(2, []), false);
}
