// Binary Tree Diameter: longest path (in edges) between any two nodes.
// Post-order returning (diameter, height) as a record. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int binaryTreeDiameter(BinaryTree tree) => _info(tree).diameter;

/// height = number of nodes on the longest downward path (0 for null).
({int diameter, int height}) _info(BinaryTree? t) {
  if (t == null) return (diameter: 0, height: 0);
  final l = _info(t.left), r = _info(t.right);
  final throughRoot = l.height + r.height; // edges of the longest path bending at t
  final best = [throughRoot, l.diameter, r.diameter].reduce((a, b) => a > b ? a : b);
  return (diameter: best, height: 1 + (l.height > r.height ? l.height : r.height));
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        1
  //       / \
  //      3   2
  //     / \
  //    7   4
  //   /     \
  //  8       5
  // /         \
  // 9          6
  final tree = BinaryTree(
    1,
    BinaryTree(3, BinaryTree(7, BinaryTree(8, BinaryTree(9))), BinaryTree(4, null, BinaryTree(5, null, BinaryTree(6)))),
    BinaryTree(2),
  );
  check(binaryTreeDiameter(tree), 6); // 9-8-7-3-4-5-6 does not pass through the root
  check(binaryTreeDiameter(BinaryTree(1)), 0);
  check(binaryTreeDiameter(BinaryTree(1, BinaryTree(2), BinaryTree(3))), 2);
}
