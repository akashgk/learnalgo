// Reconstruct BST from its pre-order traversal (duplicates go right).
// Consume values left to right; each recursive call accepts values in [lower, upper).
// O(n) time, O(n) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

BST? reconstructBst(List<int> preOrder) {
  var index = 0;
  BST? build(int? lower, int? upper) {
    if (index == preOrder.length) return null;
    final value = preOrder[index];
    if ((lower != null && value < lower) || (upper != null && value >= upper)) return null;
    index++;
    final node = BST(value);
    node.left = build(lower, value);
    node.right = build(value, upper);
    return node;
  }

  return build(null, null);
}

List<int> preOrder(BST? t) => t == null ? [] : [t.value, ...preOrder(t.left), ...preOrder(t.right)];
List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const input = [10, 4, 2, 1, 5, 17, 19, 18];
  final tree = reconstructBst(input);
  check(preOrder(tree), input);
  check(inOrder(tree), [1, 2, 4, 5, 10, 17, 18, 19]);
  check(tree!.right!.value, 17);
  check(preOrder(reconstructBst([5, 5, 5])), [5, 5, 5]);
}
