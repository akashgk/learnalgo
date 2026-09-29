# Invert Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Visit every node and swap its children

## The problem

Invert a binary tree in place: produce its mirror image, where every left subtree becomes the right subtree and vice versa. Return the root.

```
          1                          1
       /     \                    /     \
      2       3                  3       2
     / \     / \      ->        / \     / \
    4   5   6   7              7   6   5   4
   / \                                    / \
  8   9                                  9   8
```

## Step 1: Work an example by hand

Look at the root: its children 2 and 3 swapped places. Look at node 2 (now on the right): its children 4 and 5 swapped too. Every node's two children are swapped, at every level.

So "mirror the whole tree" = "swap the children of every node". The global operation decomposes into a local one. Once you see that, the only question is how to visit every node.

## Step 2: Recursive solution

```
invert(node):
    if node is null: return null
    swap(node.left, node.right)
    invert(node.left)
    invert(node.right)
```

The order does not matter. You can swap before recursing (pre-order), after (post-order), or recurse first and then assign crosswise, as `invertRecursive` does:

```dart
final left = invertRecursive(t.left);   // invert the old left subtree
t.left = invertRecursive(t.right);      // the inverted old right becomes the new left
t.right = left;                         // the inverted old left becomes the new right
```

## Step 3: Iterative solution (BFS)

Use a queue: take a node, swap its children, enqueue the children. This avoids deep recursion on very tall trees.

## Step 4: The code

<!-- CODE:START -->

Full source: [`invert_binary_tree.dart`](invert_binary_tree.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough of `invertBinaryTree` (BFS)

- `Queue<BinaryTree>()..add(tree)` starts with the root. `Queue` from `dart:collection` gives O(1) `removeFirst`; a `List` with `removeAt(0)` would be O(n) per removal.
- `final tmp = node.left; node..left = node.right..right = tmp;` swaps the two child pointers.
- The two `if (... case final x?)` lines enqueue the non-null children.
- `levelOrder` is a test helper that lists values level by level, so the test can compare shapes.

## Step 5: Dry run (BFS)

| dequeued | children before | children after | queue after |
|---|---|---|---|
| 1 | 2, 3 | 3, 2 | 3, 2 |
| 3 | 6, 7 | 7, 6 | 2, 7, 6 |
| 2 | 4, 5 | 5, 4 | 7, 6, 5, 4 |
| 7, 6, 5 | leaves | | 4 |
| 4 | 8, 9 | 9, 8 | 9, 8 |
| 9, 8 | leaves | | empty |

Level order of the result: `1, 3, 2, 7, 6, 5, 4, 9, 8`.

## Complexity

- **Time: O(n)**: each node is processed once.
- **Space:** recursive O(h) stack; BFS O(w) where w is the widest level (up to about n/2 in a complete tree).

## Common mistakes

- Assigning `node.left = node.right` and then `node.right = node.left` without a temporary (both become the same subtree).
- Recursing on `node.left` after swapping but thinking of it as the "old" left: harmless here (you still visit every node), but it confuses explanations. Be clear about the order you chose.

## Follow-ups

1. **Symmetrical Tree (medium 26):** is the tree equal to its own mirror?
2. **Are two trees mirrors of each other?** Same paired recursion as Symmetrical Tree with two roots.
3. **LeetCode #226:** identical. It became famous from a tweet by the creator of Homebrew about being rejected by Google after failing to write it, a reminder that "easy" problems still need to be practiced.

## What to remember

A global transformation that is the same at every node reduces to "apply a local operation to every node", done with any traversal.
