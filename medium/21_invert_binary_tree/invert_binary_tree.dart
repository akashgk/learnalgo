// Invert Binary Tree (mirror). BFS swapping children of every node.
// O(n) time, O(w) space for the queue (w = max width).

import 'dart:collection';

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree invertBinaryTree(BinaryTree tree) {
  final queue = Queue<BinaryTree>()..add(tree);
  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    final tmp = node.left;
    node
      ..left = node.right
      ..right = tmp;
    if (node.left case final l?) queue.add(l);
    if (node.right case final r?) queue.add(r);
  }
  return tree;
}

/// Recursive version: O(h) stack instead of O(w) queue.
BinaryTree? invertRecursive(BinaryTree? t) {
  if (t == null) return null;
  final left = invertRecursive(t.left);
  t.left = invertRecursive(t.right);
  t.right = left;
  return t;
}

List<int> levelOrder(BinaryTree root) {
  final out = <int>[];
  final q = Queue<BinaryTree>()..add(root);
  while (q.isNotEmpty) {
    final n = q.removeFirst();
    out.add(n.value);
    if (n.left case final l?) q.add(l);
    if (n.right case final r?) q.add(r);
  }
  return out;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

BinaryTree sample() => BinaryTree(
  1,
  BinaryTree(2, BinaryTree(4, BinaryTree(8), BinaryTree(9)), BinaryTree(5)),
  BinaryTree(3, BinaryTree(6), BinaryTree(7)),
);

void main() {
  check(levelOrder(invertBinaryTree(sample())), [1, 3, 2, 7, 6, 5, 4, 9, 8]);
  check(levelOrder(invertRecursive(sample())!), [1, 3, 2, 7, 6, 5, 4, 9, 8]);
}
