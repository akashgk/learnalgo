// BST Traversal: in-order, pre-order, post-order. Each O(n) time, O(n) output, O(h) stack.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

List<int> inOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    inOrderTraverse(tree.left, a);
    a.add(tree.value);
    inOrderTraverse(tree.right, a);
  }
  return a;
}

List<int> preOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    a.add(tree.value);
    preOrderTraverse(tree.left, a);
    preOrderTraverse(tree.right, a);
  }
  return a;
}

List<int> postOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    postOrderTraverse(tree.left, a);
    postOrderTraverse(tree.right, a);
    a.add(tree.value);
  }
  return a;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final tree = BST(10, BST(5, BST(2, BST(1)), BST(5)), BST(15, null, BST(22)));
  check(inOrderTraverse(tree), [1, 2, 5, 5, 10, 15, 22]);
  check(preOrderTraverse(tree), [10, 5, 2, 1, 5, 15, 22]);
  check(postOrderTraverse(tree), [1, 2, 5, 5, 22, 15, 10]);
}
