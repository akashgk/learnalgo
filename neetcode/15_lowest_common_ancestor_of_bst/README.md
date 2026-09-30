# Lowest Common Ancestor of a Binary Search Tree

**Difficulty:** Medium | **Category:** Trees | **Pattern:** Walk down using BST ordering | **Source:** LeetCode 235; NeetCode 150, Blind 75

## The problem

In a BST, return the lowest (deepest) node that has both `p` and `q` as descendants. A node counts as a descendant of itself. Both nodes exist in the tree.

```
          6
        /   \
       2     8
      / \   / \
     0   4 7   9
        / \
       3   5

LCA(2, 8) = 6    LCA(2, 4) = 2    LCA(3, 5) = 4
```

## Step 1: What the BST ordering tells you

At any node:

- if both `p` and `q` are **smaller**, both live in the left subtree, so their LCA is in the left subtree too;
- if both are **larger**, it is in the right subtree;
- otherwise they are on **different sides** (or one of them **is** this node), so this node is the lowest node containing both. Anything below it would contain at most one of them.

That is the whole algorithm: walk down from the root until the values split.

## Step 2: Compare with a general binary tree

Without the BST ordering (LeetCode 236), you do not know which side each node is on. The standard solution is a post-order DFS that returns "found p or q in this subtree", O(n). AlgoExpert medium 39 Youngest Common Ancestor uses parent pointers instead. The BST property turns an O(n) search into an O(h) walk.

## Step 3: The code

<!-- CODE:START -->

Full source: [`lowest_common_ancestor_of_bst.dart`](lowest_common_ancestor_of_bst.dart) (run it with `dart run`).

```dart
// Lowest Common Ancestor of a Binary Search Tree: p and q are in the BST; return their LCA.
// Walk down from the root: if both values are smaller go left, if both are larger go right,
// otherwise this node splits them (or is one of them): it is the LCA. O(h) time, O(1) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
  var node = root;
  while (true) {
    if (p.value < node.value && q.value < node.value) {
      node = node.left!; // both in the left subtree
    } else if (p.value > node.value && q.value > node.value) {
      node = node.right!; // both in the right subtree
    } else {
      return node; // they split here, or node is p or q
    }
  }
}
```

<!-- CODE:END -->

### Walkthrough

- The loop never needs a null check: since both nodes exist in the tree, "both smaller" guarantees a left child exists, and similarly on the right.
- The `else` branch covers `p < node < q`, `q < node < p`, and `node == p` or `node == q`.

## Step 4: Dry run

`LCA(3, 5)`:

| node | 3 and 5 vs node | action |
|---|---|---|
| 6 | both smaller | go left |
| 2 | both larger | go right |
| 4 | 3 smaller, 5 larger | **return 4** |

## Complexity

- Time: **O(h)**: O(log n) for a balanced BST, O(n) for a degenerate one.
- Space: **O(1)** (iterative).

## Edge cases

- One node is an ancestor of the other: return it.
- `p == q`: return that node.

## Common mistakes

- Using the general binary tree algorithm (correct, but O(n) and ignores the BST property).
- Comparing node identities instead of values when deciding direction.
- Stopping only on strict splits and missing the "node is p or q" case.

## Follow-ups you should be ready for

1. **General binary tree (LeetCode 236).** Post-order DFS returning the found node.
2. **Nodes might not exist.** Verify both nodes are present (a separate search) before trusting the answer.
3. **Many queries.** Binary lifting or Euler tour + RMQ give O(log n) or O(1) per query after preprocessing.

## What to remember

In a BST, the LCA is the first node on the path from the root where `p` and `q` go different ways (or where one of them sits).
