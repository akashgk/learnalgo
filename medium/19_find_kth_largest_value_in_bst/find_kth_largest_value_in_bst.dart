// Find Kth Largest Value In BST. Reverse in-order (right, node, left) visits values in
// descending order; stop after k visits. O(h + k) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

int findKthLargestValueInBst(BST tree, int k) {
  final stack = <BST>[];
  BST? node = tree;
  var visited = 0;
  while (node != null || stack.isNotEmpty) {
    while (node != null) {
      stack.add(node);
      node = node.right; // go as far right (largest) as possible
    }
    final current = stack.removeLast();
    if (++visited == k) return current.value;
    node = current.left;
  }
  throw ArgumentError('k is larger than the tree size');
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tree = BST(15, BST(5, BST(2, BST(1), BST(3)), BST(5)), BST(20, BST(17), BST(22)));
  check(findKthLargestValueInBst(tree, 3), 17);
  check(findKthLargestValueInBst(tree, 1), 22);
  check(findKthLargestValueInBst(tree, 5), 5);
  check(findKthLargestValueInBst(tree, 9), 1);
}
