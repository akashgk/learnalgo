# Lowest Common Ancestor of a Binary Tree

**Difficulty:** Medium | **Category:** Trees | **Pattern:** Post-order DFS returning "what I found" | **Source:** LeetCode 236; Grind 75

## The problem

Given a binary tree (not a BST, no parent pointers) and two nodes `p` and `q` that both exist in it, return their lowest common ancestor: the deepest node that has both as descendants. A node is a descendant of itself.

```
          3
        /   \
       5     1
      / \   / \
     6   2 0   8
        / \
       7   4

LCA(5, 1) = 3     LCA(5, 4) = 5     LCA(7, 4) = 2
```

Compare with neetcode 15 (BST: walk down by value) and AlgoExpert medium 39 Youngest Common Ancestor (with parent pointers: walk up). Here we have neither.

## Step 1: Brute force

Find the root-to-p path and the root-to-q path (two DFS searches that record the path), then walk both paths from the root until they diverge. O(n) time, O(h) extra space. A valid answer.

## Step 2: One DFS that reports upward

Let `f(node)` return:

- `node` itself if it is `p` or `q` (or null if `node` is null);
- otherwise, combine the children's results:
  - **both** children returned non-null: `p` is in one subtree and `q` in the other, so `node` is the LCA: return `node`;
  - **one** child returned non-null: pass it up (it is either `p`, `q`, or an LCA already found below);
  - neither: return null.

**Why return immediately when `node` is `p`?** If `q` is below `p`, then `p` is the LCA, and we never need to look further. If `q` is elsewhere, some ancestor will see `p` from one side and `q` from the other.

## Step 3: The code

<!-- CODE:START -->

Full source: [`lowest_common_ancestor_of_binary_tree.dart`](lowest_common_ancestor_of_binary_tree.dart) (run it with `dart run`).

```dart
// Lowest Common Ancestor of a Binary Tree (no BST ordering, no parent pointers). p and q exist.
// Post-order DFS: return p or q if found in a subtree (or their LCA once both are found).
// The first node that receives non-null results from BOTH sides is the LCA. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode? lowestCommonAncestor(TreeNode? root, TreeNode p, TreeNode q) {
  if (root == null || identical(root, p) || identical(root, q)) return root;
  final left = lowestCommonAncestor(root.left, p, q);
  final right = lowestCommonAncestor(root.right, p, q);
  if (left != null && right != null) return root; // p and q are on different sides
  return left ?? right; // pass up whatever was found (one node, or an LCA from below)
}
```

<!-- CODE:END -->

### Walkthrough

- `identical` compares node identity (two nodes could have equal values).
- Both recursive calls happen before deciding: this is post-order.
- `left ?? right` passes up whichever side found something.

## Step 4: Dry run

`LCA(7, 4)`:

| node | left result | right result | returns |
|---|---|---|---|
| 7 | | | 7 (it is p) |
| 4 | | | 4 (it is q) |
| 2 | 7 | 4 | **2** (both sides) |
| 6 | null | null | null |
| 5 | null (from 6) | 2 | 2 |
| 1 subtree | | | null |
| 3 | 2 | null | 2 |

## Complexity

- Time: **O(n)**: each node is visited at most once.
- Space: **O(h)** recursion.

## Edge cases

- One node is an ancestor of the other: returned at the ancestor, never looking below it.
- `p == q`: returns that node.

## Common mistakes

- Comparing values instead of node identity when values may repeat.
- Assuming BST ordering.
- Forgetting the guarantee: if `p` or `q` might be missing, this function can return just one of them. Then do a separate existence check.

## Follow-ups you should be ready for

1. **Nodes might not exist (LeetCode 1644).** Count how many of p and q were found during the DFS; return the LCA only if both were.
2. **LCA of many nodes (LeetCode 1676).** Same function with a set of targets.
3. **Many queries.** Binary lifting: O(n log n) preprocessing, O(log n) per query.

## What to remember

Post-order DFS: each subtree reports whether it contains p or q. The first node hearing "found" from both sides is the LCA.
