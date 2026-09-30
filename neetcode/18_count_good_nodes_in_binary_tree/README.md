# Count Good Nodes in Binary Tree

**Difficulty:** Medium | **Category:** Trees | **Pattern:** Top-down DFS carrying the path maximum | **Source:** LeetCode 1448; NeetCode 150

## The problem

A node is **good** if no node on the path from the root to it (including the root) has a value **greater** than it. Count the good nodes. The root is always good.

```
      3
     / \
    1   4        ->  4   (3, 3, 4, 5)
   /   / \
  3   1   5
```

The bottom-left `3` is good: its path is 3, 1, 3 and nothing exceeds 3.

## Step 1: What does each node need?

To decide whether a node is good, it needs only **one number**: the maximum value on the path from the root to its parent. That is information flowing **down** the tree from ancestors: a **top-down** DFS that passes it as a parameter.

(Compare with Maximum Depth, where information flows **up** from children: bottom-up.)

## Step 2: The recursion

```
count(node, maxSoFar):
  if node is null: 0
  good = node.value >= maxSoFar ? 1 : 0
  newMax = max(maxSoFar, node.value)
  return good + count(node.left, newMax) + count(node.right, newMax)
```

Start with `maxSoFar = root.value`, so the root counts as good.

## Step 3: The code

<!-- CODE:START -->

Full source: [`count_good_nodes_in_binary_tree.dart`](count_good_nodes_in_binary_tree.dart) (run it with `dart run`).

```dart
// Count Good Nodes in Binary Tree: a node is good if no node on the path from the root to it has a
// greater value. Top-down DFS carrying the maximum seen so far on the path. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

int goodNodes(TreeNode root) {
  int dfs(TreeNode? node, int maxSoFar) {
    if (node == null) return 0;
    final good = node.value >= maxSoFar ? 1 : 0; // equal counts: "no greater value" on the path
    final newMax = node.value > maxSoFar ? node.value : maxSoFar;
    return good + dfs(node.left, newMax) + dfs(node.right, newMax);
  }

  return dfs(root, root.value);
}
```

<!-- CODE:END -->

### Walkthrough

- `>=` because "no greater value" allows equal values (the bottom-left 3 in the example).
- Each child receives its own copy of `newMax`; siblings do not affect each other.

## Step 4: Dry run

| node | maxSoFar | good? | newMax |
|---|---|---|---|
| 3 (root) | 3 | yes | 3 |
| 1 | 3 | no | 3 |
| 3 (under 1) | 3 | yes | 3 |
| 4 | 3 | yes | 4 |
| 1 (under 4) | 4 | no | 4 |
| 5 | 4 | yes | 5 |

Good nodes: **4**.

## Complexity

- Time: **O(n)**.
- Space: **O(h)** recursion.

## Edge cases

- One node: 1.
- Negative values: the root starts the maximum, so no special handling.

## Common mistakes

- Using `>` (misses equal values).
- Comparing with the **parent's** value only, instead of the path maximum.
- Starting `maxSoFar` at 0 (wrong with negative values).

## Follow-ups you should be ready for

1. **Validate BST.** Top-down DFS passing a (min, max) range; see AlgoExpert medium 16.
2. **Path sum problems.** Pass the running sum down.
3. **Return the good nodes themselves.** Collect instead of count.

## What to remember

When a node's answer depends on its ancestors, pass the needed summary (here, the path maximum) down as a parameter.
