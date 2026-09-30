// Count Good Nodes in Binary Tree: a node is good if no node on the path from the root to it has a
// greater value. Top-down DFS carrying the maximum seen so far on the path. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

int goodNodes(TreeNode root) {
  int dfs(TreeNode? node, int maxSoFar) {
    if (node == null) return 0;
    final good = node.value >= maxSoFar ? 1 : 0; // equal counts: "no greater value" on the path
    final newMax = node.value > maxSoFar ? node.value : maxSoFar;
    return good + dfs(node.left, newMax) + dfs(node.right, newMax);
  }

  return dfs(root, root.value);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //       3
  //      / \
  //     1   4
  //    /   / \
  //   3   1   5
  check(goodNodes(TreeNode(3, TreeNode(1, TreeNode(3)), TreeNode(4, TreeNode(1), TreeNode(5)))), 4);
  check(goodNodes(TreeNode(3, TreeNode(3, TreeNode(4), TreeNode(2)))), 3); // 3, 3, 4
  check(goodNodes(TreeNode(1)), 1);
  check(goodNodes(TreeNode(-1, TreeNode(-2), TreeNode(0))), 2);
}
