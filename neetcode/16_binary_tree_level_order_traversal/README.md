# Binary Tree Level Order Traversal

**Difficulty:** Medium | **Category:** Trees | **Pattern:** BFS with per-level batching | **Source:** LeetCode 102; NeetCode 150, Blind 75

## The problem

Return the node values level by level, each level left to right.

```
    3
   / \
  9   20         ->  [[3], [9, 20], [15, 7]]
     /  \
    15   7
```

## Step 1: BFS visits in level order

A queue processes nodes in the order they were discovered: the root, then its children, then their children. That is level order. The only extra work is knowing **where one level ends** and the next begins.

## Step 2: Batch by level size

At the start of each round, the queue contains **exactly** the nodes of one level (the previous round removed the level above and added all of this level). So read `queue.length` once, remove that many nodes into one list, and enqueue their children for the next round.

## Step 3: DFS alternative

A DFS that carries the depth can append each value to `result[depth]`, creating the list when the depth is new. Preorder visits left before right, so each level ends up left to right. Same complexity; uses O(h) stack instead of O(w) queue.

## Step 4: The code

<!-- CODE:START -->

Full source: [`binary_tree_level_order_traversal.dart`](binary_tree_level_order_traversal.dart) (run it with `dart run`).

```dart
// Binary Tree Level Order Traversal: values level by level, left to right.
// BFS with a queue; the queue length at the start of each round is the size of that level.
// O(n) time, O(width) space.

import 'dart:collection';

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<List<int>> levelOrder(TreeNode? root) {
  final result = <List<int>>[];
  if (root == null) return result;
  final queue = Queue<TreeNode>()..add(root);
  while (queue.isNotEmpty) {
    final level = <int>[];
    for (var i = queue.length; i > 0; i--) {
      // snapshot of the level size: children added now belong to the next level
      final node = queue.removeFirst();
      level.add(node.value);
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
    result.add(level);
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `for (var i = queue.length; i > 0; i--)` snapshots the level size; the loop does not see children added during this round.
- `Queue` from `dart:collection` has O(1) `removeFirst`; a `List.removeAt(0)` would be O(n).

## Step 5: Dry run

| round | queue at start | level | queue at end |
|---|---|---|---|
| 1 | 3 | [3] | 9, 20 |
| 2 | 9, 20 | [9, 20] | 15, 7 |
| 3 | 15, 7 | [15, 7] | empty |

## Complexity

- Time: **O(n)**.
- Space: **O(w)** for the queue, w = maximum width (up to about n/2 in a complete tree), plus the output.

## Edge cases

- Empty tree: `[]`.
- A single node.
- Skewed trees: one node per level.

## Common mistakes

- Using `queue.length` as the loop condition while also adding to the queue (mixes levels).
- `List.removeAt(0)` in Dart (quadratic).

## Follow-ups you should be ready for

1. **Bottom-up order (LeetCode 107).** Reverse the result.
2. **Zigzag (LeetCode 103).** Reverse every other level, or add to the front with a deque.
3. **Right side view.** The last value of each level; see neetcode 17.
4. **Average of levels, largest value per level.** Same loop, different aggregation.

## What to remember

BFS already visits level by level; snapshot the queue size at the start of each round to separate the levels.
