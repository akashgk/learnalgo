// Binary Tree Right Side View: the value you would see at each level looking from the right,
// i.e. the last node of every level. DFS visiting right before left, recording the first node
// seen at each depth. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<int> rightSideView(TreeNode? root) {
  final view = <int>[];
  void dfs(TreeNode? node, int depth) {
    if (node == null) return;
    // The first node reached at a new depth is the rightmost one, because right is explored first.
    if (depth == view.length) view.add(node.value);
    dfs(node.right, depth + 1);
    dfs(node.left, depth + 1);
  }

  dfs(root, 0);
  return view;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //     1
  //    / \
  //   2   3
  //    \   \
  //     5   4
  check(rightSideView(TreeNode(1, TreeNode(2, null, TreeNode(5)), TreeNode(3, null, TreeNode(4)))), [1, 3, 4]);
  // The left subtree is deeper, so its bottom node is visible from the right.
  check(rightSideView(TreeNode(1, TreeNode(2, TreeNode(4)), TreeNode(3))), [1, 3, 4]);
  check(rightSideView(TreeNode(1, null, TreeNode(3))), [1, 3]);
  check(rightSideView(null), []);
}
