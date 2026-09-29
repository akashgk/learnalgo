# Height Balanced Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Bottom-up DFS with a failure sentinel

## The problem

A binary tree is **height balanced** if, for **every** node, the heights of its left and right subtrees differ by at most 1. Return whether the given tree is height balanced.

```
balanced:                  not balanced:
        1                          1
      /   \                      /   \
     2     3                    2     5
    / \     \                  /
   4   5     6                3
      / \                    /
     7   8                  4

                (node 2: left height 2, right height 0)
```

## Step 1: The definition says "every node"

Checking only the root is the classic mistake. A tree can have equal-height subtrees at the root and still be badly unbalanced deeper down. The check must happen at every node.

## Step 2: Brute force

For each node, compute the heights of its two subtrees with a separate function and compare. The height of a subtree costs O(its size). Summed over all nodes this is O(n^2) for a skewed tree (O(n log n) for a balanced one).

**Duplicated work:** heights of the same subtrees are recomputed for every ancestor.

## Step 3: Optimize: one bottom-up pass

Compute heights bottom-up (post-order), and check balance at the same time. Each call returns its subtree's height, or a **sentinel** `-1` meaning "unbalanced somewhere below".

```
height(node):
    if node is null: return 0
    l = height(node.left);   if l == -1: return -1      # early exit
    r = height(node.right);  if r == -1: return -1
    if |l - r| > 1: return -1
    return 1 + max(l, r)
```

The tree is balanced iff `height(root) != -1`.

A record `(isBalanced, height)` is an equally good (and more explicit) return type. The sentinel is shorter and makes early exit easy. Mention both.

## Step 4: The code

<!-- CODE:START -->

Full source: [`height_balanced_binary_tree.dart`](height_balanced_binary_tree.dart) (run it with `dart run`).

```dart
// Height Balanced Binary Tree: for every node, |height(left) - height(right)| <= 1.
// Post-order returning height, or -1 as an "unbalanced" signal. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool heightBalancedBinaryTree(BinaryTree tree) => _height(tree) != -1;

int _height(BinaryTree? t) {
  if (t == null) return 0;
  final l = _height(t.left);
  if (l == -1) return -1; // short-circuit: no need to explore further
  final r = _height(t.right);
  if (r == -1 || (l - r).abs() > 1) return -1;
  return 1 + (l > r ? l : r);
}
```

<!-- CODE:END -->

### Walkthrough

- `_height` returns `0` for an empty tree, the height in nodes otherwise, or `-1` on failure.
- `if (l == -1) return -1;` skips the right subtree entirely once a problem is found.
- `(l - r).abs() > 1` is the balance condition at this node.

## Step 5: Dry run on the unbalanced tree

| node | l | r | returns |
|---|---|---|---|
| 4 | 0 | 0 | 1 |
| 3 | 1 | 0 | 2 |
| 2 | 2 | 0 | **-1** (difference 2) |
| 1 | -1 | not computed | -1 |

Result: false.

## Complexity

- **Time: O(n)**: each node is visited at most once.
- **Space: O(h)**.

## Common mistakes

- Checking balance only at the root.
- Confusing "balanced" with "complete" or "full" trees (different definitions).
- Using the sentinel -1 while also treating a null tree's height as -1 (conflict). Here null has height 0.

## Follow-ups

1. **LeetCode #110:** identical.
2. **AVL trees** maintain exactly this property after every insert/delete by rotating nodes, which guarantees O(log n) height.
3. **Minimum number of nodes in a balanced tree of height h** follows a Fibonacci-like recurrence `N(h) = N(h-1) + N(h-2) + 1`, which proves an AVL tree's height is O(log n).

## What to remember

Compute heights bottom-up and check the condition in the same pass. Use a sentinel or a record to propagate failure upward.
