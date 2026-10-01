// Minimum Height Trees: in an undirected tree with n nodes, return every node that, chosen as the
// root, gives the minimum height. Those are the 1 or 2 centers of the tree's longest path.
// Peel leaves layer by layer (topological trimming); the last 1 or 2 nodes are the answer.
// O(n) time and space.

List<int> findMinHeightTrees(int n, List<List<int>> edges) {
  if (n == 1) return [0];
  final adj = List.generate(n, (_) => <int>{});
  for (final e in edges) {
    adj[e[0]].add(e[1]);
    adj[e[1]].add(e[0]);
  }
  var leaves = [
    for (var v = 0; v < n; v++)
      if (adj[v].length == 1) v,
  ];
  var remaining = n;
  while (remaining > 2) {
    remaining -= leaves.length;
    final next = <int>[];
    for (final leaf in leaves) {
      final neighbor = adj[leaf].first; // a leaf has exactly one neighbor left
      adj[neighbor].remove(leaf);
      if (adj[neighbor].length == 1) next.add(neighbor); // it just became a leaf
    }
    leaves = next;
  }
  return leaves..sort();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    findMinHeightTrees(4, [
      [1, 0],
      [1, 2],
      [1, 3],
    ]),
    [1],
  );
  check(
    findMinHeightTrees(6, [
      [3, 0],
      [3, 1],
      [3, 2],
      [3, 4],
      [5, 4],
    ]),
    [3, 4],
  );
  check(findMinHeightTrees(1, []), [0]);
  check(
    findMinHeightTrees(2, [
      [0, 1],
    ]),
    [0, 1],
  );
  check(
    findMinHeightTrees(5, [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ]),
    [2],
  ); // a path of 5: the middle
}
