// Redundant Connection: a tree of n nodes (1..n) plus one extra edge. Return the edge that can be
// removed to leave a tree; if several work, the one that appears last in the input.
// Union-find: the first edge whose endpoints are already connected closes the cycle.
// O(n * alpha(n)) time, O(n) space.

List<int> findRedundantConnection(List<List<int>> edges) {
  final parent = List<int>.generate(edges.length + 1, (i) => i);
  final rank = List<int>.filled(edges.length + 1, 0);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]]; // path halving
      x = parent[x];
    }
    return x;
  }

  for (final e in edges) {
    final a = find(e[0]), b = find(e[1]);
    if (a == b) return e; // already connected: this edge closes the only cycle
    // Union by rank keeps the trees shallow.
    if (rank[a] < rank[b]) {
      parent[a] = b;
    } else if (rank[a] > rank[b]) {
      parent[b] = a;
    } else {
      parent[b] = a;
      rank[a]++;
    }
  }
  return const []; // unreachable for valid input
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    findRedundantConnection([
      [1, 2],
      [1, 3],
      [2, 3],
    ]),
    [2, 3],
  );
  check(
    findRedundantConnection([
      [1, 2],
      [2, 3],
      [3, 4],
      [1, 4],
      [1, 5],
    ]),
    [1, 4],
  );
}
