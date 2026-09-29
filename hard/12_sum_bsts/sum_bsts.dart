// Sum BSTs: sum of the sizes of all maximal BST subtrees with at least 3 nodes.
// If a subtree is a BST (>= 3 nodes), count it once and do not add its nested BST subtrees.
// Post-order with per-subtree info. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

typedef _Info = ({bool isBst, int min, int max, int size, int total});

int sumBsts(BinaryTree tree) => _info(tree).total;

_Info _info(BinaryTree? t) {
  if (t == null) {
    return (isBst: true, min: 1 << 62, max: -(1 << 62), size: 0, total: 0);
  }
  final l = _info(t.left), r = _info(t.right);
  // Duplicates go right: left values strictly less, right values >= node.
  final isBst = l.isBst && r.isBst && l.max < t.value && t.value <= r.min;
  final size = isBst ? 1 + l.size + r.size : 0;
  final total = isBst && size >= 3 ? size : l.total + r.total;
  return (
    isBst: isBst,
    min: [t.value, l.min, r.min].reduce((a, b) => a < b ? a : b),
    max: [t.value, l.max, r.max].reduce((a, b) => a > b ? a : b),
    size: size,
    total: total,
  );
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //            8
  //         /     \
  //        2       9
  //      /   \    / \
  //     1    10  5   15
  //         /  \      \
  //        5    15     22
  final tree = BinaryTree(
    8,
    BinaryTree(2, BinaryTree(1), BinaryTree(10, BinaryTree(5), BinaryTree(15))),
    BinaryTree(9, BinaryTree(5), BinaryTree(15, null, BinaryTree(22))),
  );
  // Subtree at 2 is a BST of size 5 (it contains the size-3 BST at 10, counted once).
  // Subtree at 9 is a BST of size 4. The root is not a BST (15 in its left subtree > 8).
  check(sumBsts(tree), 5 + 4);
  check(sumBsts(BinaryTree(1, BinaryTree(2), BinaryTree(3))), 0);
  check(sumBsts(BinaryTree(2, BinaryTree(1), BinaryTree(3))), 3);
}
