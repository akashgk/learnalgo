// Binary Tree Level Order Traversal: values level by level, left to right.
// BFS with a queue; the queue length at the start of each round is the size of that level.
// O(n) time, O(width) space.

import 'dart:collection';

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<List<int>> levelOrder(TreeNode? root) {
  final result = <List<int>>[];
  if (root == null) return result;
  final queue = Queue<TreeNode>()..add(root);
  while (queue.isNotEmpty) {
    final level = <int>[];
    for (var i = queue.length; i > 0; i--) {
      // snapshot of the level size: children added now belong to the next level
      final node = queue.removeFirst();
      level.add(node.value);
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
    result.add(level);
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final t = TreeNode(3, TreeNode(9), TreeNode(20, TreeNode(15), TreeNode(7)));
  check(levelOrder(t), [
    [3],
    [9, 20],
    [15, 7],
  ]);
  check(levelOrder(TreeNode(1)), [
    [1],
  ]);
  check(levelOrder(null), []);
  check(levelOrder(TreeNode(1, TreeNode(2, TreeNode(4)), TreeNode(3, null, TreeNode(5)))), [
    [1],
    [2, 3],
    [4, 5],
  ]);
}
