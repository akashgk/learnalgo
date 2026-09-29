// Right Sibling Tree: rewire every node's `right` pointer to its right neighbor on the same
// level (null at the end of a level), for a tree where the level structure is determined by the
// original tree. In place, no queue. O(n) time, O(d) space (recursion).
//
// Order matters: a left child reads its parent's ORIGINAL right child, so the parent must be
// rewired only after its left subtree is done; a right child reads its parent's NEW right
// pointer (the parent's sibling), so the parent must be rewired before its right subtree.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree rightSiblingTree(BinaryTree root) {
  _mutate(root, null, false);
  return root;
}

void _mutate(BinaryTree? node, BinaryTree? parent, bool isLeftChild) {
  if (node == null) return;
  final left = node.left, right = node.right;
  _mutate(left, node, true);
  if (parent == null) {
    node.right = null;
  } else if (isLeftChild) {
    node.right = parent.right; // parent not rewired yet: this is my sibling
  } else {
    node.right = parent.right?.left; // parent.right is now the parent's right neighbor
  }
  _mutate(right, node, false);
}

List<int> chain(BinaryTree start) => [for (BinaryTree? n = start; n != null; n = n.right) n.value];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //              1
  //          /       \
  //         2         3
  //       /   \     /   \
  //      4     5   6     7
  //     / \     \  /    / \
  //    8   9   10 11   12  13
  //               /
  //              14
  final n = {for (var v = 1; v <= 14; v++) v: BinaryTree(v)};
  void link(int p, int? l, int? r) {
    n[p]!
      ..left = l == null ? null : n[l]
      ..right = r == null ? null : n[r];
  }

  link(1, 2, 3);
  link(2, 4, 5);
  link(3, 6, 7);
  link(4, 8, 9);
  link(5, null, 10);
  link(6, 11, null);
  link(7, 12, 13);
  link(11, 14, null);
  rightSiblingTree(n[1]!);
  // Expected (AlgoExpert's definition):
  //   1
  //   2 ----------- 3
  //   4 --- 5 ----- 6 --- 7
  //   8 - 9    10 - 11    12 - 13
  //                 14
  // 9 -> null because 5 (its parent's sibling) has no left child.
  // 11 -> null because 11 is 6's left child and 6 had no right child.
  check(chain(n[1]!), [1]);
  check(chain(n[2]!), [2, 3]);
  check(chain(n[4]!), [4, 5, 6, 7]);
  check(chain(n[8]!), [8, 9]);
  check(chain(n[10]!), [10, 11]);
  check(chain(n[12]!), [12, 13]);
  check(chain(n[14]!), [14]);
}
