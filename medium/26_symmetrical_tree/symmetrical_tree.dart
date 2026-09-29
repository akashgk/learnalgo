// Symmetrical Tree: left subtree is a mirror image of the right subtree.
// Compare mirrored pairs (outer with outer, inner with inner). O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool symmetricalTree(BinaryTree tree) => _mirrors(tree.left, tree.right);

bool _mirrors(BinaryTree? a, BinaryTree? b) {
  if (a == null || b == null) return a == b; // both null -> true, one null -> false
  return a.value == b.value && _mirrors(a.left, b.right) && _mirrors(a.right, b.left);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final sym = BinaryTree(
    1,
    BinaryTree(2, BinaryTree(3, BinaryTree(5), BinaryTree(6)), BinaryTree(4)),
    BinaryTree(2, BinaryTree(4), BinaryTree(3, BinaryTree(6), BinaryTree(5))),
  );
  check(symmetricalTree(sym), true);
  check(symmetricalTree(BinaryTree(1, BinaryTree(2, null, BinaryTree(3)), BinaryTree(2, null, BinaryTree(3)))), false);
  check(symmetricalTree(BinaryTree(1)), true);
}
