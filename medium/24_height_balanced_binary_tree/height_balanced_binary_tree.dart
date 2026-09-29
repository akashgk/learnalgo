// Height Balanced Binary Tree: for every node, |height(left) - height(right)| <= 1.
// Post-order returning height, or -1 as an "unbalanced" signal. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool heightBalancedBinaryTree(BinaryTree tree) => _height(tree) != -1;

int _height(BinaryTree? t) {
  if (t == null) return 0;
  final l = _height(t.left);
  if (l == -1) return -1; // short-circuit: no need to explore further
  final r = _height(t.right);
  if (r == -1 || (l - r).abs() > 1) return -1;
  return 1 + (l > r ? l : r);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final balanced = BinaryTree(
    1,
    BinaryTree(2, BinaryTree(4), BinaryTree(5, BinaryTree(7), BinaryTree(8))),
    BinaryTree(3, null, BinaryTree(6)),
  );
  check(heightBalancedBinaryTree(balanced), true);
  final unbalanced = BinaryTree(1, BinaryTree(2, BinaryTree(3, BinaryTree(4))), BinaryTree(5));
  check(heightBalancedBinaryTree(unbalanced), false);
  check(heightBalancedBinaryTree(BinaryTree(1)), true);
}
