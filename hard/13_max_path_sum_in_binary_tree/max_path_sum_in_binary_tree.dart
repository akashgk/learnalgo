// Max Path Sum In Binary Tree: path between any two nodes (at least one node), values may be
// negative. Post-order returning the best downward "branch" sum; update a global best with the
// "bent" path through each node. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int maxPathSum(BinaryTree tree) {
  var best = tree.value;

  /// Max sum of a path starting at [t] and going down (possibly just t itself).
  int branch(BinaryTree? t) {
    if (t == null) return 0;
    final l = branch(t.left), r = branch(t.right);
    final leftGain = l > 0 ? l : 0, rightGain = r > 0 ? r : 0; // drop negative branches
    final throughT = t.value + leftGain + rightGain;
    if (throughT > best) best = throughT;
    return t.value + (leftGain > rightGain ? leftGain : rightGain);
  }

  branch(tree);
  return best;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tree = BinaryTree(1, BinaryTree(2, BinaryTree(4), BinaryTree(5)), BinaryTree(3, BinaryTree(6), BinaryTree(7)));
  check(maxPathSum(tree), 18); // 5 + 2 + 1 + 3 + 7
  check(maxPathSum(BinaryTree(-3)), -3);
  check(maxPathSum(BinaryTree(-10, BinaryTree(9), BinaryTree(20, BinaryTree(15), BinaryTree(7)))), 42);
  check(maxPathSum(BinaryTree(-2, BinaryTree(-1))), -1);
}
