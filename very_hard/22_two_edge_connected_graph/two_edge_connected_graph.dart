// Two-Edge-Connected Graph: connected, and removing any single edge keeps it connected
// (no bridges). Tarjan's low-link DFS. O(v + e) time, O(v) space.

bool twoEdgeConnectedGraph(List<List<int>> edges) {
  final n = edges.length;
  if (n == 0) return true;
  final disc = List<int>.filled(n, -1); // discovery time
  final low = List<int>.filled(n, 0); // earliest discovery time reachable via one back edge
  var time = 0;
  var hasBridge = false;

  void dfs(int u, int parent) {
    disc[u] = low[u] = time++;
    var skippedParent = false;
    for (final v in edges[u]) {
      if (v == parent && !skippedParent) {
        skippedParent = true; // skip the tree edge once (parallel edges still count)
        continue;
      }
      if (disc[v] == -1) {
        dfs(v, u);
        if (low[v] < low[u]) low[u] = low[v];
        if (low[v] > disc[u]) hasBridge = true; // v's subtree cannot reach above u
      } else if (disc[v] < low[u]) {
        low[u] = disc[v];
      }
    }
  }

  dfs(0, -1);
  final connected = disc.every((d) => d != -1);
  return connected && !hasBridge;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    twoEdgeConnectedGraph([
      [1, 2, 5],
      [0, 2],
      [0, 1, 3],
      [2, 4, 5],
      [3, 5],
      [0, 3, 4],
    ]),
    true,
  );
  check(
    twoEdgeConnectedGraph([
      [1],
      [0, 2],
      [1],
    ]),
    false,
  ); // a path: every edge is a bridge
  check(
    twoEdgeConnectedGraph([
      [1, 2],
      [0, 2],
      [0, 1],
      [],
    ]),
    false,
  ); // disconnected
  check(twoEdgeConnectedGraph([]), true);
  check(twoEdgeConnectedGraph([[]]), true); // single vertex
}
