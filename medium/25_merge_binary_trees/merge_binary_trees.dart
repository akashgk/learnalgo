// Merge Binary Trees: overlapping nodes are summed; otherwise the existing node is used.
// Merges into tree1 in place. O(n) time where n = nodes in the smaller overlap, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree? mergeBinaryTrees(BinaryTree? tree1, BinaryTree? tree2) {
  if (tree1 == null) return tree2;
  if (tree2 == null) return tree1;
  tree1.value += tree2.value;
  tree1.left = mergeBinaryTrees(tree1.left, tree2.left);
  tree1.right = mergeBinaryTrees(tree1.right, tree2.right);
  return tree1;
}

List<int?> preOrder(BinaryTree? t) => t == null ? [null] : [t.value, ...preOrder(t.left), ...preOrder(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final t1 = BinaryTree(1, BinaryTree(3, BinaryTree(7), BinaryTree(4)), BinaryTree(2));
  final t2 = BinaryTree(1, BinaryTree(5, BinaryTree(2)), BinaryTree(9, BinaryTree(7), BinaryTree(6)));
  check(preOrder(mergeBinaryTrees(t1, t2)), [2, 8, 9, null, null, 4, null, null, 11, 7, null, null, 6, null, null]);
}
