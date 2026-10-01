// Lowest Common Ancestor of a Binary Tree (no BST ordering, no parent pointers). p and q exist.
// Post-order DFS: return p or q if found in a subtree (or their LCA once both are found).
// The first node that receives non-null results from BOTH sides is the LCA. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode? lowestCommonAncestor(TreeNode? root, TreeNode p, TreeNode q) {
  if (root == null || identical(root, p) || identical(root, q)) return root;
  final left = lowestCommonAncestor(root.left, p, q);
  final right = lowestCommonAncestor(root.right, p, q);
  if (left != null && right != null) return root; // p and q are on different sides
  return left ?? right; // pass up whatever was found (one node, or an LCA from below)
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //          3
  //        /   \
  //       5     1
  //      / \   / \
  //     6   2 0   8
  //        / \
  //       7   4
  final n7 = TreeNode(7), n4 = TreeNode(4), n2 = TreeNode(2, n7, n4);
  final n6 = TreeNode(6), n5 = TreeNode(5, n6, n2);
  final n0 = TreeNode(0), n8 = TreeNode(8), n1 = TreeNode(1, n0, n8);
  final root = TreeNode(3, n5, n1);
  check(lowestCommonAncestor(root, n5, n1)!.value, 3);
  check(lowestCommonAncestor(root, n5, n4)!.value, 5); // a node is its own ancestor
  check(lowestCommonAncestor(root, n7, n4)!.value, 2);
  check(lowestCommonAncestor(root, n6, n4)!.value, 5);
  check(lowestCommonAncestor(root, n0, n0)!.value, 0);
}
