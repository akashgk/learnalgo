// Flatten Binary Tree into a doubly linked list in in-order order, in place:
// left = previous node, right = next node. Return the leftmost node.
// Recursive, each call returns its flattened (leftmost, rightmost). O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree flattenBinaryTree(BinaryTree root) => _flatten(root).$1;

(BinaryTree, BinaryTree) _flatten(BinaryTree node) {
  var leftmost = node, rightmost = node;
  if (node.left case final l?) {
    final (lFirst, lLast) = _flatten(l);
    lLast.right = node;
    node.left = lLast;
    leftmost = lFirst;
  }
  if (node.right case final r?) {
    final (rFirst, rLast) = _flatten(r);
    node.right = rFirst;
    rFirst.left = node;
    rightmost = rLast;
  }
  return (leftmost, rightmost);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //          1
  //        /   \
  //       2     3
  //      / \   /
  //     4   5 6
  //        / \
  //       7   8
  final tree = BinaryTree(
    1,
    BinaryTree(2, BinaryTree(4), BinaryTree(5, BinaryTree(7), BinaryTree(8))),
    BinaryTree(3, BinaryTree(6)),
  );
  final head = flattenBinaryTree(tree);
  final forward = <int>[];
  var tail = head;
  for (BinaryTree? n = head; n != null; n = n.right) {
    forward.add(n.value);
    tail = n;
  }
  final backward = [for (BinaryTree? n = tail; n != null; n = n.left) n.value];
  check(forward, [4, 2, 7, 5, 8, 1, 6, 3]);
  check(backward, [3, 6, 1, 8, 5, 7, 2, 4]);
}
