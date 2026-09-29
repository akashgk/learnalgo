// Floyd-Warshall: shortest distances between every pair of vertices (negative edges allowed).
// dist[i][j] is improved using intermediate vertex k, for k = 0..n-1 in the outer loop.
// Detects negative cycles (dist[i][i] < 0). O(V^3) time, O(V^2) space.

const inf = 1 << 50;

/// Returns the distance matrix (inf = unreachable), or null if a negative cycle exists.
List<List<int>>? floydWarshall(int n, List<List<int>> edges) {
  final dist = List.generate(n, (i) => List<int>.generate(n, (j) => i == j ? 0 : inf));
  for (final e in edges) {
    if (e[2] < dist[e[0]][e[1]]) dist[e[0]][e[1]] = e[2]; // keep the cheapest parallel edge
  }
  for (var k = 0; k < n; k++) {
    // After this round, dist[i][j] is the shortest path using only intermediates from {0..k}.
    for (var i = 0; i < n; i++) {
      if (dist[i][k] == inf) continue;
      for (var j = 0; j < n; j++) {
        if (dist[k][j] == inf) continue;
        final through = dist[i][k] + dist[k][j];
        if (through < dist[i][j]) dist[i][j] = through;
      }
    }
  }
  for (var i = 0; i < n; i++) {
    if (dist[i][i] < 0) return null;
  }
  return dist;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final d = floydWarshall(4, [
    [0, 1, 3],
    [1, 0, 2],
    [0, 3, 5],
    [1, 3, 4],
    [3, 2, 2],
    [2, 1, 1],
  ])!;
  check(d, [
    [0, 3, 7, 5],
    [2, 0, 6, 4],
    [3, 1, 0, 5],
    [5, 3, 2, 0],
  ]);
  final neg = floydWarshall(3, [
    [0, 1, 4],
    [1, 2, -2],
    [0, 2, 5],
  ])!;
  check(neg[0][2], 2); // negative edge, no negative cycle
  check(
    floydWarshall(2, [
      [0, 1, 1],
      [1, 0, -2],
    ]),
    null,
  ); // cycle of weight -1
  check(
    floydWarshall(2, [
      [0, 1, 7],
    ])![1][0],
    inf,
  ); // unreachable
}
