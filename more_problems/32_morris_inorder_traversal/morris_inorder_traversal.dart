// Morris Inorder Traversal: inorder traversal in O(1) extra space (no stack, no recursion).
// Temporarily thread each node's inorder predecessor back to it, then remove the thread.
// O(n) time (each edge is walked at most a constant number of times), O(1) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<int> morrisInorder(TreeNode? root) {
  final result = <int>[];
  var cur = root;
  while (cur != null) {
    if (cur.left == null) {
      // Nothing on the left: visit and go right (possibly along a thread).
      result.add(cur.value);
      cur = cur.right;
      continue;
    }
    // Predecessor = rightmost node of the left subtree (stop if it already threads back to cur).
    var pred = cur.left!;
    while (pred.right != null && pred.right != cur) {
      pred = pred.right!;
    }
    if (pred.right == null) {
      // First visit: create the thread, then explore the left subtree.
      pred.right = cur;
      cur = cur.left;
    } else {
      // Second visit (came back through the thread): left subtree is done.
      pred.right = null; // restore the tree
      result.add(cur.value);
      cur = cur.right;
    }
  }
  return result;
}

List<int> recursiveInorder(TreeNode? t) =>
    t == null ? [] : [...recursiveInorder(t.left), t.value, ...recursiveInorder(t.right)];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //        4
  //      /   \
  //     2     6
  //    / \   / \
  //   1   3 5   7
  final t = TreeNode(4, TreeNode(2, TreeNode(1), TreeNode(3)), TreeNode(6, TreeNode(5), TreeNode(7)));
  check(morrisInorder(t), [1, 2, 3, 4, 5, 6, 7]);
  check(recursiveInorder(t), [1, 2, 3, 4, 5, 6, 7]); // the tree was restored
  final skewed = TreeNode(3, TreeNode(2, TreeNode(1)));
  check(morrisInorder(skewed), [1, 2, 3]);
  check(morrisInorder(TreeNode(1, null, TreeNode(2, null, TreeNode(3)))), [1, 2, 3]);
  check(morrisInorder(null), []);
}
