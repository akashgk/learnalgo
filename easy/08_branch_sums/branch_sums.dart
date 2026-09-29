// Branch Sums
// DFS carrying the running sum; record it at each leaf. Left-to-right order.
// O(n) time, O(n) space (output has at most ~n/2 leaves; recursion depth O(h)).

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

List<int> branchSums(BinaryTree root) {
  final sums = <int>[];
  void dfs(BinaryTree? node, int running) {
    if (node == null) return;
    final total = running + node.value;
    if (node.left == null && node.right == null) {
      sums.add(total);
      return;
    }
    dfs(node.left, total);
    dfs(node.right, total);
  }

  dfs(root, 0);
  return sums;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //          1
  //       /     \
  //      2       3
  //     / \     / \
  //    4   5   6   7
  //   / \  /
  //  8  9 10
  final tree = BinaryTree(
    1,
    BinaryTree(2, BinaryTree(4, BinaryTree(8), BinaryTree(9)), BinaryTree(5, BinaryTree(10))),
    BinaryTree(3, BinaryTree(6), BinaryTree(7)),
  );
  check(branchSums(tree), [15, 16, 18, 10, 11]);
  check(branchSums(BinaryTree(1)), [1]);
}
