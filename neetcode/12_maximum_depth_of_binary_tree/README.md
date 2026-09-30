# Maximum Depth of Binary Tree

**Difficulty:** Easy | **Category:** Trees | **Pattern:** Bottom-up DFS, or BFS level counting | **Source:** LeetCode 104; NeetCode 150, Blind 75

## The problem

Return the number of nodes on the longest path from the root down to a leaf. An empty tree has depth 0.

```
    3
   / \
  9   20        ->  3
     /  \
    15   7
```

## Step 1: Think recursively

The depth of a tree is 1 (for the root) plus the depth of its **deeper** subtree. The empty tree has depth 0. That definition **is** the code:

```
depth(null) = 0
depth(node) = 1 + max(depth(left), depth(right))
```

This is the simplest example of **bottom-up** tree recursion: each node combines answers returned by its children. Binary Tree Diameter and Height Balanced Binary Tree (AlgoExpert medium 22 and 24) extend exactly this function.

## Step 2: Iterative alternative (BFS)

Process the tree level by level with a queue. Each round removes exactly the nodes of one level (`queue.length` at the start of the round) and adds their children. The number of rounds is the depth. Useful when recursion depth is a concern (a degenerate tree of 10^5 nodes can overflow the call stack).

## Step 3: The code

<!-- CODE:START -->

Full source: [`maximum_depth_of_binary_tree.dart`](maximum_depth_of_binary_tree.dart) (run it with `dart run`).

```dart
// Maximum Depth of Binary Tree: number of nodes on the longest root-to-leaf path.
// Recursive DFS: depth(node) = 1 + max(depth(left), depth(right)). O(n) time, O(h) space.
// Iterative BFS alternative: count levels. O(n) time, O(width) space.

import 'dart:collection';

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

int maxDepth(TreeNode? root) {
  if (root == null) return 0;
  final l = maxDepth(root.left), r = maxDepth(root.right);
  return 1 + (l > r ? l : r);
}

int maxDepthBfs(TreeNode? root) {
  if (root == null) return 0;
  final queue = Queue<TreeNode>()..add(root);
  var levels = 0;
  while (queue.isNotEmpty) {
    levels++;
    for (var i = queue.length; i > 0; i--) {
      // exactly the nodes of the current level
      final node = queue.removeFirst();
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
  }
  return levels;
}
```

<!-- CODE:END -->

### Walkthrough

- `maxDepth` is the definition above.
- `maxDepthBfs` fixes the loop count at the start of each round: `for (var i = queue.length; i > 0; i--)`. Children added during the round wait for the next one.

## Step 4: Dry run (recursive)

| node | left depth | right depth | returns |
|---|---|---|---|
| 9 | 0 | 0 | 1 |
| 15 | 0 | 0 | 1 |
| 7 | 0 | 0 | 1 |
| 20 | 1 | 1 | 2 |
| 3 | 1 | 2 | **3** |

## Complexity

- Time: **O(n)** for both.
- Space: **O(h)** recursion (h = height, O(n) worst case); BFS uses **O(w)** (w = maximum width, up to about n/2).

## Edge cases

- Empty tree: 0.
- A chain: depth n.

## Common mistakes

- Returning 1 for the empty tree.
- Counting edges instead of nodes (the problem counts nodes; some definitions count edges: clarify).
- In BFS, looping `while` over the queue without fixing the level size (then levels are not separated).

## Follow-ups you should be ready for

1. **Minimum depth (LeetCode 111).** Careful: a node with one child is not a leaf. BFS stops at the first leaf.
2. **Iterative DFS with a stack of (node, depth).**
3. **Diameter, balanced check.** Same recursion, returning more information.

## What to remember

Depth = 1 + max(child depths), empty = 0. The recursion is the definition.
