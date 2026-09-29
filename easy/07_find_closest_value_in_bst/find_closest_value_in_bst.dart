// Find Closest Value In BST
// Walk down from the root, keeping the best candidate; the BST property tells us which
// subtree could hold something closer. Average O(log n), worst O(n) time; O(1) space iteratively.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

int findClosestValueInBst(BST tree, int target) {
  var closest = tree.value;
  BST? node = tree;
  while (node != null) {
    if ((target - node.value).abs() < (target - closest).abs()) closest = node.value;
    if (target < node.value) {
      node = node.left;
    } else if (target > node.value) {
      node = node.right;
    } else {
      break; // exact match
    }
  }
  return closest;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        10
  //      /    \
  //     5      15
  //    / \    /  \
  //   2   5  13   22
  //  /         \
  // 1           14
  final tree = BST(10, BST(5, BST(2, BST(1)), BST(5)), BST(15, BST(13, null, BST(14)), BST(22)));
  check(findClosestValueInBst(tree, 12), 13);
  check(findClosestValueInBst(tree, 100), 22);
  check(findClosestValueInBst(tree, -5), 1);
  check(findClosestValueInBst(tree, 14), 14);
}
