// Same Tree: are two binary trees identical in shape and values?
// Simultaneous DFS: both null, or both present with equal values and equal subtrees.
// O(min(n, m)) time (stops at the first difference), O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

bool isSameTree(TreeNode? p, TreeNode? q) {
  if (p == null || q == null) return p == q; // equal only if both are null
  return p.value == q.value && isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isSameTree(TreeNode(1, TreeNode(2), TreeNode(3)), TreeNode(1, TreeNode(2), TreeNode(3))), true);
  check(isSameTree(TreeNode(1, TreeNode(2)), TreeNode(1, null, TreeNode(2))), false); // same values, other shape
  check(isSameTree(TreeNode(1, TreeNode(2), TreeNode(1)), TreeNode(1, TreeNode(1), TreeNode(2))), false);
  check(isSameTree(null, null), true);
  check(isSameTree(TreeNode(0), null), false);
}
