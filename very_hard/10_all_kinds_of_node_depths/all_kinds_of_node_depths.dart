// All Kinds Of Node Depths: sum, over every node, of the node depths in its subtree.
// Bottom-up: depthSum(node) = sum over children of (depthSum(child) + size(child)).
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int allKindsOfNodeDepths(BinaryTree root) => _info(root).total;

({int size, int depthSum, int total}) _info(BinaryTree? t) {
  if (t == null) return (size: 0, depthSum: 0, total: 0);
  final l = _info(t.left), r = _info(t.right);
  // Every node in a child's subtree is one level deeper when measured from t.
  final depthSum = l.depthSum + l.size + r.depthSum + r.size;
  return (size: 1 + l.size + r.size, depthSum: depthSum, total: depthSum + l.total + r.total);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tree = BinaryTree(
    1,
    BinaryTree(2, BinaryTree(4, BinaryTree(8), BinaryTree(9)), BinaryTree(5)),
    BinaryTree(3, BinaryTree(6), BinaryTree(7)),
  );
  check(allKindsOfNodeDepths(tree), 26);
  check(allKindsOfNodeDepths(BinaryTree(1)), 0);
}
