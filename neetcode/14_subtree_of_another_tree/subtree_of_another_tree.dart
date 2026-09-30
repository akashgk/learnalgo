// Subtree of Another Tree: does root contain a node whose entire subtree equals subRoot?
// For every node of root, run Same Tree against subRoot. O(n * m) time worst case, O(h) space.
// (An O(n + m) alternative serializes both trees and runs string matching; see the README.)

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

bool isSubtree(TreeNode? root, TreeNode? subRoot) {
  if (subRoot == null) return true; // the empty tree is a subtree of everything
  if (root == null) return false;
  return _same(root, subRoot) || isSubtree(root.left, subRoot) || isSubtree(root.right, subRoot);
}

bool _same(TreeNode? p, TreeNode? q) {
  if (p == null || q == null) return p == q;
  return p.value == q.value && _same(p.left, q.left) && _same(p.right, q.right);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //     3            4
  //    / \          / \
  //   4   5        1   2
  //  / \
  // 1   2
  final root = TreeNode(3, TreeNode(4, TreeNode(1), TreeNode(2)), TreeNode(5));
  final sub = TreeNode(4, TreeNode(1), TreeNode(2));
  check(isSubtree(root, sub), true);
  // Same as above but 2 has a child 0: the 4-subtree is no longer an exact match.
  final root2 = TreeNode(3, TreeNode(4, TreeNode(1), TreeNode(2, TreeNode(0))), TreeNode(5));
  check(isSubtree(root2, sub), false);
  check(isSubtree(TreeNode(1, TreeNode(1)), TreeNode(1)), true); // matches the leaf, not the root
  check(isSubtree(null, TreeNode(1)), false);
}
