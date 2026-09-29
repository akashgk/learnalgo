// Find Successor (in-order) in a binary tree with parent pointers.
// Case 1: right subtree exists -> leftmost node of it.
// Case 2: otherwise climb until we arrive from a left child. O(h) time, O(1) space.

class BinaryTree {
  BinaryTree(this.value, {this.left, this.right, this.parent});
  int value;
  BinaryTree? left;
  BinaryTree? right;
  BinaryTree? parent;
}

BinaryTree? findSuccessor(BinaryTree tree, BinaryTree node) {
  if (node.right case final right?) {
    var current = right;
    while (current.left != null) {
      current = current.left!;
    }
    return current;
  }
  var current = node;
  while (current.parent != null && identical(current.parent!.right, current)) {
    current = current.parent!;
  }
  return current.parent;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        1
  //       / \
  //      2   3
  //     / \
  //    4   5
  //   /
  //  6
  final n1 = BinaryTree(1), n2 = BinaryTree(2), n3 = BinaryTree(3);
  final n4 = BinaryTree(4), n5 = BinaryTree(5), n6 = BinaryTree(6);
  void link(BinaryTree p, BinaryTree? l, BinaryTree? r) {
    p
      ..left = l
      ..right = r;
    l?.parent = p;
    r?.parent = p;
  }

  link(n1, n2, n3);
  link(n2, n4, n5);
  link(n4, n6, null);
  // in-order: 6 4 2 5 1 3
  check(findSuccessor(n1, n5)?.value, 1);
  check(findSuccessor(n1, n2)?.value, 5);
  check(findSuccessor(n1, n6)?.value, 4);
  check(findSuccessor(n1, n3)?.value, null);
}
