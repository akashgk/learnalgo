// Vertical Order Traversal of a Binary Tree (LeetCode 987 rules).
// Root at (row 0, col 0); left child (row + 1, col - 1); right child (row + 1, col + 1).
// Output columns left to right; within a column sort by row, then by value.
// Collect (col, row, value) triples with DFS, sort, group. O(n log n) time, O(n) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<List<int>> verticalTraversal(TreeNode? root) {
  final entries = <(int col, int row, int value)>[];
  void dfs(TreeNode? node, int row, int col) {
    if (node == null) return;
    entries.add((col, row, node.value));
    dfs(node.left, row + 1, col - 1);
    dfs(node.right, row + 1, col + 1);
  }

  dfs(root, 0, 0);
  entries.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
    return a.$3.compareTo(b.$3); // same cell: smaller value first
  });
  final result = <List<int>>[];
  int? currentCol;
  for (final (col, _, value) in entries) {
    if (col != currentCol) {
      result.add([]);
      currentCol = col;
    }
    result.last.add(value);
  }
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //     3
  //    / \
  //   9   20
  //      /  \
  //     15   7
  check(verticalTraversal(TreeNode(3, TreeNode(9), TreeNode(20, TreeNode(15), TreeNode(7)))), [
    [9],
    [3, 15],
    [20],
    [7],
  ]);
  //        1
  //      /   \
  //     2     3
  //    / \   / \
  //   4   5 6   7      5 and 6 share (row 2, col 0): sorted by value
  final t = TreeNode(1, TreeNode(2, TreeNode(4), TreeNode(5)), TreeNode(3, TreeNode(6), TreeNode(7)));
  check(verticalTraversal(t), [
    [4],
    [2],
    [1, 5, 6],
    [3],
    [7],
  ]);
  final u = TreeNode(1, TreeNode(2, TreeNode(4), TreeNode(6)), TreeNode(3, TreeNode(5), TreeNode(7)));
  check(verticalTraversal(u), [
    [4],
    [2],
    [1, 5, 6],
    [3],
    [7],
  ]);
  check(verticalTraversal(null), []);
}
