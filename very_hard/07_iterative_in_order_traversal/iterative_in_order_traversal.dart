// Iterative In-order Traversal with parent pointers and O(1) extra space.
// Track the previous node to know whether we came from the parent, the left child, or the right.
// O(n) time, O(1) space.

class BinaryTree {
  BinaryTree(this.value, {this.left, this.right, this.parent});
  int value;
  BinaryTree? left;
  BinaryTree? right;
  BinaryTree? parent;
}

void iterativeInOrderTraversal(BinaryTree tree, void Function(BinaryTree) callback) {
  BinaryTree? previous;
  BinaryTree? current = tree;
  while (current != null) {
    BinaryTree? next;
    if (previous == null || identical(previous, current.parent)) {
      // Arrived from above: go left if possible; otherwise visit and go right or up.
      if (current.left != null) {
        next = current.left;
      } else {
        callback(current);
        next = current.right ?? current.parent;
      }
    } else if (identical(previous, current.left)) {
      // Left subtree done: visit, then go right or up.
      callback(current);
      next = current.right ?? current.parent;
    } else {
      // Right subtree done: go up.
      next = current.parent;
    }
    previous = current;
    current = next;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        1
  //      /   \
  //     2     3
  //    /     / \
  //   4     6   7
  //    \
  //     9
  BinaryTree node(int v, [BinaryTree? l, BinaryTree? r]) {
    final n = BinaryTree(v, left: l, right: r);
    l?.parent = n;
    r?.parent = n;
    return n;
  }

  final tree = node(1, node(2, node(4, null, node(9))), node(3, node(6), node(7)));
  final out = <int>[];
  iterativeInOrderTraversal(tree, (n) => out.add(n.value));
  check(out, [4, 9, 2, 1, 6, 3, 7]);
}
