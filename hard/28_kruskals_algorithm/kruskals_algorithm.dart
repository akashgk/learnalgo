// Kruskal's Algorithm: minimum spanning tree(s) of an undirected weighted graph.
// Input and output use the same adjacency format: edges[u] = [[v, w], ...] (both directions).
// Sort edges + Union-Find. O(e log e) time, O(v + e) space.

List<List<List<int>>> kruskalsAlgorithm(List<List<List<int>>> edges) {
  final list = <(int, int, int)>[
    for (var u = 0; u < edges.length; u++)
      for (final [v, w] in edges[u])
        if (u < v) (w, u, v), // each undirected edge once
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  final parent = List<int>.generate(edges.length, (i) => i);
  final rank = List<int>.filled(edges.length, 0);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]]; // path halving
      x = parent[x];
    }
    return x;
  }

  final mst = List.generate(edges.length, (_) => <List<int>>[]);
  for (final (w, u, v) in list) {
    final ru = find(u), rv = find(v);
    if (ru == rv) continue; // would create a cycle
    if (rank[ru] < rank[rv]) {
      parent[ru] = rv;
    } else if (rank[ru] > rank[rv]) {
      parent[rv] = ru;
    } else {
      parent[rv] = ru;
      rank[ru]++;
    }
    mst[u].add([v, w]);
    mst[v].add([u, w]);
  }
  return mst;
}

int totalWeight(List<List<List<int>>> g) => g.expand((e) => e).fold(0, (s, e) => s + e[1]) ~/ 2;

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final graph = [
    [[1, 3], [2, 5]],
    [[0, 3], [2, 10], [3, 12]],
    [[0, 5], [1, 10]],
    [[1, 12]],
  ];
  final mst = kruskalsAlgorithm(graph);
  check(mst, [[[1, 3], [2, 5]], [[0, 3], [3, 12]], [[0, 5]], [[1, 12]]]);
  check(totalWeight(mst), 20);
}
