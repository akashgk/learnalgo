// Find Nodes Distance K: values of nodes exactly k edges from the node with value `target`.
// Build parent pointers, then BFS outward treating the tree as an undirected graph.
// O(n) time, O(n) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

List<int> findNodesDistanceK(BinaryTree tree, int target, int k) {
  final parent = <BinaryTree, BinaryTree?>{tree: null};
  BinaryTree? start;
  final stack = [tree];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    if (node.value == target) start = node;
    for (final child in [node.left, node.right].nonNulls) {
      parent[child] = node;
      stack.add(child);
    }
  }
  if (start == null) return [];

  final seen = <BinaryTree>{start};
  var frontier = [start];
  for (var d = 0; d < k && frontier.isNotEmpty; d++) {
    final next = <BinaryTree>[];
    for (final node in frontier) {
      for (final nb in [node.left, node.right, parent[node]].nonNulls) {
        if (seen.add(nb)) next.add(nb);
      }
    }
    frontier = next;
  }
  return [for (final n in frontier) n.value];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        1
  //       / \
  //      2   3
  //     / \    \
  //    4   5    6
  //            / \
  //           7   8
  final tree = BinaryTree(1, BinaryTree(2, BinaryTree(4), BinaryTree(5)), BinaryTree(3, null, BinaryTree(6, BinaryTree(7), BinaryTree(8))));
  check(findNodesDistanceK(tree, 3, 2)..sort(), [2, 7, 8]);
  check(findNodesDistanceK(tree, 1, 0), [1]);
  check(findNodesDistanceK(tree, 4, 10), []);
}
