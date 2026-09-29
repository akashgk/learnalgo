// Validate Three Nodes: is nodeTwo a descendant of one of (nodeOne, nodeThree) and an ancestor
// of the other? Uses BST search downward from each node. O(h) time, O(1) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

bool validateThreeNodes(BST nodeOne, BST nodeTwo, BST nodeThree) {
  if (_isDescendant(nodeTwo, nodeOne)) return _isDescendant(nodeThree, nodeTwo);
  if (_isDescendant(nodeTwo, nodeThree)) return _isDescendant(nodeOne, nodeTwo);
  return false;
}

/// True if [target] is found by BST search starting from [node] (and target != node).
bool _isDescendant(BST node, BST target) {
  BST? current = node;
  while (current != null && !identical(current, target)) {
    current = target.value < current.value ? current.left : current.right;
  }
  return identical(current, target) && !identical(node, target);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //          5
  //       /     \
  //      2       7
  //    /   \    /  \
  //   1     4  6    8
  //  /     /
  // 0     3
  final n3 = BST(3), n0 = BST(0), n6 = BST(6), n8 = BST(8);
  final n1 = BST(1, n0), n4 = BST(4, n3);
  final n2 = BST(2, n1, n4), n7 = BST(7, n6, n8);
  final n5 = BST(5, n2, n7);
  check(validateThreeNodes(n5, n2, n3), true);
  check(validateThreeNodes(n3, n2, n5), true); // reversed order also valid
  check(validateThreeNodes(n5, n7, n3), false);
  check(validateThreeNodes(n2, n2, n3), false); // a node is not its own descendant here
}
