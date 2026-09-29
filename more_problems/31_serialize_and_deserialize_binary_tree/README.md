# Serialize and Deserialize Binary Tree

**Difficulty:** Hard | **Category:** Binary trees | **Pattern:** Preorder with null markers | **Source:** LeetCode 297; Striver A2Z, NeetCode 150

## The problem

Design two functions: `serialize(root)` turns a binary tree into a string, and `deserialize(data)` turns that string back into the same tree. The format is up to you.

```
    1
   / \
  2   3        <->   "1,2,#,#,3,4,#,#,5,#,#"
     / \
    4   5
```

## Step 1: Why one plain traversal is not enough

Preorder alone, `1, 2, 3, 4, 5`, fits many trees: is 3 the right child of 1 or the left child of 2? A traversal loses the **shape**. More_problems 30 needed **two** traversals (preorder + inorder) and unique values to recover it.

## Step 2: Record the shape explicitly

Write a marker (`#`) for every **null child**. Now the preorder sequence is unambiguous: after reading a node's value, the next tokens describe its complete left subtree (ending when all its nulls are accounted for), and then its right subtree.

Why is it unambiguous? A tree with `k` nodes has exactly `k + 1` null children. Reading preorder, every value opens two child slots and every `#` closes one; the moment the open slots reach zero, the subtree is complete. So the parser always knows where a subtree ends. Duplicates are fine too: nothing depends on searching for a value.

## Step 3: Deserialize by mirroring serialize

The parser is the serializer run backwards:

```
build():
  token = next token
  if token == '#': return null
  node = new node(token)
  node.left = build()
  node.right = build()
  return node
```

It consumes tokens in exactly the order `serialize` produced them.

## Step 4: The code

<!-- CODE:START -->

Full source: [`serialize_and_deserialize_binary_tree.dart`](serialize_and_deserialize_binary_tree.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `serialize` does a preorder DFS, adding `'#'` for null.
- `deserialize` splits once, then `build` reads tokens with an index `i` shared across the recursion.
- Negative numbers work because the separator is a comma, not a character that can appear in a number.

## Step 5: Dry run (deserialize)

Tokens `1 2 # # 3 4 # # 5 # #`:

| token | action |
|---|---|
| 1 | create 1, build its left |
| 2 | create 2, build its left |
| # | 2.left = null |
| # | 2.right = null, 2 is done, back to 1: build 1.right |
| 3 | create 3, build its left |
| 4 | create 4 |
| # # | 4 has no children |
| 5 | create 5 as 3.right |
| # # | 5 has no children, done |

## Complexity

- Time: **O(n)** for both functions.
- Space: **O(n)** for the string/tokens; O(h) recursion.

## Edge cases

- Empty tree: `"#"`.
- Negative and multi-digit values.
- Deep skewed trees: recursion depth n. An iterative version with an explicit stack avoids stack overflow.

## Common mistakes

- Omitting null markers.
- Separating tokens with nothing (`"12##"` is ambiguous between 1, 2 and 12).
- Using a queue-based BFS format but forgetting to emit trailing nulls consistently between the two functions.

## Follow-ups you should be ready for

1. **Level-order format (LeetCode's own).** BFS, writing `null` for missing children; deserialize with a queue of parents.
2. **Serialize a BST more compactly (LeetCode 449).** Preorder without null markers is enough, because BST ordering recovers the shape (value bounds).
3. **N-ary tree.** Write each node's child count after its value.
4. **Compare with more_problems 30.** There, the shape was recovered from two traversals; here, it is written directly.

## What to remember

A traversal plus explicit null markers fully describes a tree. Deserialize by running the same traversal and consuming tokens in the same order.
