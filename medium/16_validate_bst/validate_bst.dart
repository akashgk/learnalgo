// Validate BST: every node must be within (min, max) bounds inherited from ancestors.
// Left subtree: strictly less. Right subtree: greater or equal.
// O(n) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

bool validateBst(BST? tree, [int? min, int? max]) {
  if (tree == null) return true;
  if (min != null && tree.value < min) return false; // must be >= min
  if (max != null && tree.value >= max) return false; // must be < max
  return validateBst(tree.left, min, tree.value) && validateBst(tree.right, tree.value, max);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final valid = BST(10, BST(5, BST(2, BST(1)), BST(5)), BST(15, BST(13, null, BST(14)), BST(22)));
  check(validateBst(valid), true);
  // 11 is in the left subtree of 10, so it violates the ancestor bound even though 11 > 5.
  final invalid = BST(10, BST(5, BST(2), BST(11)), BST(15));
  check(validateBst(invalid), false);
  check(validateBst(BST(10, BST(10))), false); // equal values belong on the right
  check(validateBst(BST(10, null, BST(10))), true);
}
