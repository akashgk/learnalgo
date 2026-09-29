// Evaluate Expression Tree
// Leaves are non-negative operands; internal nodes are operators:
// -1 add, -2 subtract, -3 divide (truncate toward zero), -4 multiply.
// Postorder evaluation. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int evaluateExpressionTree(BinaryTree tree) {
  if (tree.value >= 0) return tree.value;
  final l = evaluateExpressionTree(tree.left!);
  final r = evaluateExpressionTree(tree.right!);
  return switch (tree.value) {
    -1 => l + r,
    -2 => l - r,
    -3 => l ~/ r, // ~/ truncates toward zero, as required
    -4 => l * r,
    _ => throw ArgumentError('unknown operator ${tree.value}'),
  };
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  // ((2 - 3) + (8 / 3)) * (2 * 3)  =  (-1 + 2) * 6  =  6
  final tree = BinaryTree(
    -4,
    BinaryTree(-1, BinaryTree(-2, BinaryTree(2), BinaryTree(3)), BinaryTree(-3, BinaryTree(8), BinaryTree(3))),
    BinaryTree(-4, BinaryTree(2), BinaryTree(3)),
  );
  check(evaluateExpressionTree(tree), 6);
  check(evaluateExpressionTree(BinaryTree(-3, BinaryTree(-7 + 14), BinaryTree(2))), 3);
  check(evaluateExpressionTree(BinaryTree(-3, BinaryTree(-2, BinaryTree(0), BinaryTree(7)), BinaryTree(2))), -3);
}
