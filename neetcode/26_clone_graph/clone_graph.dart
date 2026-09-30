// Clone Graph: deep-copy a connected undirected graph given one node.
// DFS with a map original -> copy. The map doubles as the visited set and breaks cycles.
// O(V + E) time, O(V) space.

class Node {
  Node(this.value);
  int value;
  final neighbors = <Node>[];
}

Node? cloneGraph(Node? node) {
  if (node == null) return null;
  final copies = <Node, Node>{};
  Node clone(Node original) {
    final existing = copies[original];
    if (existing != null) return existing;
    final copy = Node(original.value);
    copies[original] = copy; // register BEFORE recursing, or a cycle recurses forever
    for (final n in original.neighbors) {
      copy.neighbors.add(clone(n));
    }
    return copy;
  }

  return clone(node);
}

/// Builds a graph from an adjacency list (1-indexed values, like LeetCode) and returns node 1.
Node? build(List<List<int>> adj) {
  if (adj.isEmpty) return null;
  final nodes = [for (var i = 1; i <= adj.length; i++) Node(i)];
  for (var i = 0; i < adj.length; i++) {
    for (final j in adj[i]) {
      nodes[i].neighbors.add(nodes[j - 1]);
    }
  }
  return nodes[0];
}

/// Adjacency list reachable from [start], ordered by value, for comparison.
List<List<int>> encode(Node? start) {
  if (start == null) return [];
  final seen = <Node>{};
  final stack = [start];
  while (stack.isNotEmpty) {
    final n = stack.removeLast();
    if (seen.add(n)) stack.addAll(n.neighbors);
  }
  final sorted = seen.toList()..sort((a, b) => a.value.compareTo(b.value));
  return [
    for (final n in sorted) [for (final m in n.neighbors) m.value],
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // 1 - 2
  // |   |
  // 4 - 3
  final adj = [
    [2, 4],
    [1, 3],
    [2, 4],
    [1, 3],
  ];
  final original = build(adj);
  final copy = cloneGraph(original);
  check(encode(copy), adj);
  check(identical(copy, original), false);
  // No node of the copy is shared with the original.
  final originals = <Node>{};
  void collect(Node n) {
    if (originals.add(n)) n.neighbors.forEach(collect);
  }

  collect(original!);
  var shared = false;
  void walk(Node n, Set<Node> seen) {
    if (!seen.add(n)) return;
    if (originals.contains(n)) shared = true;
    for (final m in n.neighbors) {
      walk(m, seen);
    }
  }

  walk(copy!, {});
  check(shared, false);
  check(encode(cloneGraph(build([<int>[]]))), [<int>[]]); // single node, no edges
  check(cloneGraph(null), null);
}
