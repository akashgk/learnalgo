// Node Depths
// Sum of every node's distance from the root. Iterative DFS with (node, depth) records.
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int nodeDepths(BinaryTree root) {
  var total = 0;
  final stack = <(BinaryTree, int)>[(root, 0)];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    total += depth;
    if (node.left case final l?) stack.add((l, depth + 1));
    if (node.right case final r?) stack.add((r, depth + 1));
  }
  return total;
}

/// Recursive one-liner version for comparison.
int nodeDepthsRecursive(BinaryTree? node, [int depth = 0]) => node == null
    ? 0
    : depth + nodeDepthsRecursive(node.left, depth + 1) + nodeDepthsRecursive(node.right, depth + 1);

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
  check(nodeDepths(tree), 16);
  check(nodeDepthsRecursive(tree), 16);
  check(nodeDepths(BinaryTree(1)), 0);
}
