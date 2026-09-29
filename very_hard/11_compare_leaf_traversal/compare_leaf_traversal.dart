// Compare Leaf Traversal: do two binary trees have the same leaves, left to right?
// Walk both trees' leaves lazily in lockstep with explicit stacks.
// O(n + m) time, O(h1 + h2) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool compareLeafTraversal(BinaryTree tree1, BinaryTree tree2) {
  final a = _leaves(tree1).iterator, b = _leaves(tree2).iterator;
  while (true) {
    final hasA = a.moveNext(), hasB = b.moveNext();
    if (!hasA || !hasB) return hasA == hasB; // both must end together
    if (a.current != b.current) return false;
  }
}

/// Lazily yields leaf values in left-to-right order using an explicit stack.
Iterable<int> _leaves(BinaryTree root) sync* {
  final stack = [root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    if (node.left == null && node.right == null) {
      yield node.value;
      continue;
    }
    if (node.right case final r?) stack.add(r); // push right first so left is processed first
    if (node.left case final l?) stack.add(l);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final t1 = BinaryTree(1, BinaryTree(2, BinaryTree(4), BinaryTree(5, BinaryTree(7), BinaryTree(8))), BinaryTree(3, null, BinaryTree(6)));
  final t2 = BinaryTree(1, BinaryTree(2, BinaryTree(4), BinaryTree(7)), BinaryTree(3, null, BinaryTree(5, BinaryTree(8), BinaryTree(6))));
  check(compareLeafTraversal(t1, t2), true); // leaves: 4 7 8 6
  check(compareLeafTraversal(BinaryTree(1, BinaryTree(2)), BinaryTree(1, BinaryTree(3))), false);
  check(compareLeafTraversal(BinaryTree(1, BinaryTree(2), BinaryTree(3)), BinaryTree(1, BinaryTree(2))), false);
}
