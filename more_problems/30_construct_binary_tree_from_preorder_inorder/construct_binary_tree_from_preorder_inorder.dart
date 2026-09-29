// Construct Binary Tree from Preorder and Inorder Traversal (values are unique).
// The next preorder value is the root; its inorder position splits left and right subtrees.
// A value -> inorder index map makes each split O(1). O(n) time, O(n) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode? buildTree(List<int> preorder, List<int> inorder) {
  final inIndex = {for (var i = 0; i < inorder.length; i++) inorder[i]: i};
  var pre = 0; // next unused preorder position
  // Builds the subtree whose inorder range is [lo, hi].
  TreeNode? build(int lo, int hi) {
    if (lo > hi) return null;
    final rootValue = preorder[pre++];
    final mid = inIndex[rootValue]!;
    final left = build(lo, mid - 1); // preorder lists the whole left subtree before the right
    final right = build(mid + 1, hi);
    return TreeNode(rootValue, left, right);
  }

  return build(0, inorder.length - 1);
}

List<int> preorderOf(TreeNode? t) => t == null ? [] : [t.value, ...preorderOf(t.left), ...preorderOf(t.right)];
List<int> inorderOf(TreeNode? t) => t == null ? [] : [...inorderOf(t.left), t.value, ...inorderOf(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final pre = [3, 9, 20, 15, 7], ino = [9, 3, 15, 20, 7];
  final t = buildTree(pre, ino)!;
  check(t.value, 3);
  check(t.left!.value, 9);
  check(t.right!.value, 20);
  check(t.right!.left!.value, 15);
  check(preorderOf(t), pre);
  check(inorderOf(t), ino);
  final pre2 = [1, 2, 4, 5, 3, 6], ino2 = [4, 2, 5, 1, 6, 3];
  final t2 = buildTree(pre2, ino2);
  check(preorderOf(t2), pre2);
  check(inorderOf(t2), ino2);
  check(buildTree([-1], [-1])!.value, -1);
  check(buildTree([], []), null);
  // Left-skewed chain: inorder is preorder reversed.
  check(inorderOf(buildTree([1, 2, 3], [3, 2, 1])), [3, 2, 1]);
}
