// Two-Colorable (bipartite check) on a connected undirected graph (adjacency list).
// DFS assigning alternating colors; conflict means not two-colorable. O(v + e) time, O(v) space.

bool twoColorable(List<List<int>> edges) {
  final color = List<bool?>.filled(edges.length, null);
  for (var start = 0; start < edges.length; start++) {
    if (color[start] != null) continue; // handles disconnected graphs too
    color[start] = true;
    final stack = [start];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      for (final next in edges[node]) {
        if (color[next] == null) {
          color[next] = !color[node]!;
          stack.add(next);
        } else if (color[next] == color[node]) {
          return false; // includes self loops
        }
      }
    }
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    twoColorable([
      [1, 2],
      [0, 2],
      [0, 1],
    ]),
    false,
  ); // triangle
  check(
    twoColorable([
      [1, 3],
      [0, 2],
      [1, 3],
      [0, 2],
    ]),
    true,
  ); // square
  check(
    twoColorable([
      [0],
    ]),
    false,
  ); // self loop
  check(twoColorable([[]]), true);
}
