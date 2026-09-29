// Cycle In Graph (directed, adjacency list). DFS with three colors:
// white = unvisited, grey = on the current DFS path, black = fully explored.
// A grey-to-grey edge is a back edge, i.e. a cycle. O(v + e) time, O(v) space.

enum _Color { white, grey, black }

bool cycleInGraph(List<List<int>> edges) {
  final color = List<_Color>.filled(edges.length, _Color.white);

  bool dfs(int node) {
    color[node] = _Color.grey;
    for (final next in edges[node]) {
      if (color[next] == _Color.grey) return true;
      if (color[next] == _Color.white && dfs(next)) return true;
    }
    color[node] = _Color.black;
    return false;
  }

  for (var v = 0; v < edges.length; v++) {
    if (color[v] == _Color.white && dfs(v)) return true;
  }
  return false;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(cycleInGraph([[1, 3], [2, 3, 4], [0], [], [2, 5], []]), true);
  check(cycleInGraph([[1, 2], [2], []]), false); // diamond-ish, no cycle
  check(cycleInGraph([[0]]), true); // self loop
  check(cycleInGraph([[], []]), false);
}
