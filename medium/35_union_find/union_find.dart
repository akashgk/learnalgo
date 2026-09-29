// Union Find (Disjoint Set Union) with path compression and union by rank.
// createSet/find/union in amortized O(alpha(n)) (effectively constant). O(n) space.

class UnionFind {
  final _parent = <int, int>{};
  final _rank = <int, int>{};

  void createSet(int value) {
    _parent[value] = value;
    _rank[value] = 0;
  }

  /// Representative of [value]'s set, or null if [value] was never created.
  int? find(int value) {
    if (!_parent.containsKey(value)) return null;
    var root = value;
    while (_parent[root] != root) {
      root = _parent[root]!;
    }
    // Path compression: point every node on the path directly at the root.
    var node = value;
    while (node != root) {
      final next = _parent[node]!;
      _parent[node] = root;
      node = next;
    }
    return root;
  }

  void union(int a, int b) {
    final ra = find(a), rb = find(b);
    if (ra == null || rb == null || ra == rb) return;
    // Union by rank: attach the shorter tree under the taller one.
    final rankA = _rank[ra]!, rankB = _rank[rb]!;
    if (rankA < rankB) {
      _parent[ra] = rb;
    } else if (rankA > rankB) {
      _parent[rb] = ra;
    } else {
      _parent[rb] = ra;
      _rank[ra] = rankA + 1;
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final uf = UnionFind();
  check(uf.find(1), null);
  for (var i = 1; i <= 5; i++) {
    uf.createSet(i);
  }
  check(uf.find(1) == uf.find(2), false);
  uf
    ..union(1, 2)
    ..union(3, 4)
    ..union(2, 4);
  check(uf.find(1) == uf.find(3), true);
  check(uf.find(5) == uf.find(1), false);
  uf.union(5, 99); // unknown value: no-op
  check(uf.find(5), 5);
}
