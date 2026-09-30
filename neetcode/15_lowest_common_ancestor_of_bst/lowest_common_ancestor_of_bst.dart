// Lowest Common Ancestor of a Binary Search Tree: p and q are in the BST; return their LCA.
// Walk down from the root: if both values are smaller go left, if both are larger go right,
// otherwise this node splits them (or is one of them): it is the LCA. O(h) time, O(1) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
  var node = root;
  while (true) {
    if (p.value < node.value && q.value < node.value) {
      node = node.left!; // both in the left subtree
    } else if (p.value > node.value && q.value > node.value) {
      node = node.right!; // both in the right subtree
    } else {
      return node; // they split here, or node is p or q
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //         6
  //       /   \
  //      2     8
  //     / \   / \
  //    0   4 7   9
  //       / \
  //      3   5
  final n3 = TreeNode(3), n5 = TreeNode(5), n4 = TreeNode(4, n3, n5);
  final n0 = TreeNode(0), n2 = TreeNode(2, n0, n4);
  final n7 = TreeNode(7), n9 = TreeNode(9), n8 = TreeNode(8, n7, n9);
  final root = TreeNode(6, n2, n8);
  check(lowestCommonAncestor(root, n2, n8).value, 6);
  check(lowestCommonAncestor(root, n2, n4).value, 2); // a node is its own ancestor
  check(lowestCommonAncestor(root, n3, n5).value, 4);
  check(lowestCommonAncestor(root, n0, n5).value, 2);
  check(lowestCommonAncestor(root, n7, n7).value, 7);
}
