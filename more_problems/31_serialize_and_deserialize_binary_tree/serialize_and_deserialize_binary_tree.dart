// Serialize and Deserialize Binary Tree.
// Preorder with explicit null markers ("#"), comma separated. The null markers make the
// preorder sequence unambiguous, so one traversal is enough. O(n) time, O(n) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

String serialize(TreeNode? root) {
  final out = <String>[];
  void dfs(TreeNode? node) {
    if (node == null) {
      out.add('#');
      return;
    }
    out.add('${node.value}');
    dfs(node.left);
    dfs(node.right);
  }

  dfs(root);
  return out.join(',');
}

TreeNode? deserialize(String data) {
  final tokens = data.split(',');
  var i = 0;
  // Consumes exactly the tokens of one subtree, mirroring serialize's order.
  TreeNode? build() {
    final token = tokens[i++];
    if (token == '#') return null;
    final node = TreeNode(int.parse(token));
    node.left = build();
    node.right = build();
    return node;
  }

  return build();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  //     1
  //    / \
  //   2   3
  //      / \
  //     4   5
  final t = TreeNode(1, TreeNode(2), TreeNode(3, TreeNode(4), TreeNode(5)));
  final s = serialize(t);
  check(s, '1,2,#,#,3,4,#,#,5,#,#');
  check(serialize(deserialize(s)), s); // round trip
  check(serialize(null), '#');
  check(deserialize('#'), null);
  final neg = TreeNode(-10, null, TreeNode(-200));
  check(serialize(deserialize(serialize(neg))), '-10,#,-200,#,#');
}
