// Split Binary Tree: can removing one edge split the tree into two trees of equal sum?
// Return that sum, or 0. Compute total, then look for a proper subtree summing to total / 2.
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int splitBinaryTree(BinaryTree tree) {
  int sum(BinaryTree? t) => t == null ? 0 : t.value + sum(t.left) + sum(t.right);
  final total = sum(tree);
  if (total.isOdd) return 0;
  final half = total ~/ 2;
  var found = false;

  int visit(BinaryTree? t) {
    if (t == null) return 0;
    final s = t.value + visit(t.left) + visit(t.right);
    if (s == half && !identical(t, tree)) found = true; // the whole tree is not a split
    return s;
  }

  visit(tree);
  return found ? half : 0;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tree = BinaryTree(
    1,
    BinaryTree(3, BinaryTree(6, BinaryTree(2), BinaryTree(-5))),
    BinaryTree(-2, BinaryTree(5, BinaryTree(2)), BinaryTree(2)),
  );
  check(splitBinaryTree(tree), 7); // total 14; subtree rooted at -2 sums to 7
  check(splitBinaryTree(BinaryTree(1, BinaryTree(2))), 0);
  // Total 0: only a proper subtree summing to 0 counts, never the whole tree.
  check(splitBinaryTree(BinaryTree(0)), 0);
  check(splitBinaryTree(BinaryTree(0, BinaryTree(0))), 0); // split exists, each half sums to 0
}
