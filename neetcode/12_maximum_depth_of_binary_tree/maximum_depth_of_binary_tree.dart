// Maximum Depth of Binary Tree: number of nodes on the longest root-to-leaf path.
// Recursive DFS: depth(node) = 1 + max(depth(left), depth(right)). O(n) time, O(h) space.
// Iterative BFS alternative: count levels. O(n) time, O(width) space.

import 'dart:collection';

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

int maxDepth(TreeNode? root) {
  if (root == null) return 0;
  final l = maxDepth(root.left), r = maxDepth(root.right);
  return 1 + (l > r ? l : r);
}

int maxDepthBfs(TreeNode? root) {
  if (root == null) return 0;
  final queue = Queue<TreeNode>()..add(root);
  var levels = 0;
  while (queue.isNotEmpty) {
    levels++;
    for (var i = queue.length; i > 0; i--) {
      // exactly the nodes of the current level
      final node = queue.removeFirst();
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
  }
  return levels;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //     3
  //    / \
  //   9   20
  //      /  \
  //     15   7
  final t = TreeNode(3, TreeNode(9), TreeNode(20, TreeNode(15), TreeNode(7)));
  for (final f in [maxDepth, maxDepthBfs]) {
    check(f(t), 3);
    check(f(TreeNode(1, null, TreeNode(2))), 2);
    check(f(null), 0);
    check(f(TreeNode(1, TreeNode(2, TreeNode(3, TreeNode(4))))), 4); // left chain
  }
}
