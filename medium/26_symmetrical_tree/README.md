# Symmetrical Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Paired traversal (mirror comparison)

## The problem

Return whether a binary tree is symmetric around its center: the left subtree is a mirror image of the right subtree, in both structure and values.

```
symmetric:                     not symmetric:
          1                          1
        /   \                      /   \
       2     2                    2     2
      / \   / \                    \     \
     3   4 4   3                    3     3
    / \       / \
   5   6     6   5
```

## Step 1: Work an example by hand

Fold the tree along its vertical center line. The left 2 lands on the right 2. The left 2's **left** child (3) lands on the right 2's **right** child (3). The left 2's **right** child (4) lands on the right 2's **left** child (4). So mirrored pairs are:

- outer with outer: `a.left` with `b.right`,
- inner with inner: `a.right` with `b.left`.

## Step 2: Paired recursion

Two subtrees `a` and `b` are mirrors if:

1. both are null (mirrors), or
2. both exist, have equal values, `a.left` mirrors `b.right`, and `a.right` mirrors `b.left`.

If exactly one is null, they are not mirrors.

Start with `mirrors(root.left, root.right)`.

## Step 3: The code

<!-- CODE:START -->

Full source: [`symmetrical_tree.dart`](symmetrical_tree.dart) (run it with `dart run`).

```dart
// Symmetrical Tree: left subtree is a mirror image of the right subtree.
// Compare mirrored pairs (outer with outer, inner with inner). O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool symmetricalTree(BinaryTree tree) => _mirrors(tree.left, tree.right);

bool _mirrors(BinaryTree? a, BinaryTree? b) {
  if (a == null || b == null) return a == b; // both null -> true, one null -> false
  return a.value == b.value && _mirrors(a.left, b.right) && _mirrors(a.right, b.left);
}
```

<!-- CODE:END -->

### Walkthrough

- `if (a == null || b == null) return a == b;` covers all null cases in one line: if both are null, `a == b` is true; if only one is null, it is false.
- `a.value == b.value && _mirrors(a.left, b.right) && _mirrors(a.right, b.left)` checks the values and the outer and inner pairs. `&&` stops at the first mismatch.

## Step 4: Dry run on the non-symmetric tree

| pair | values | result |
|---|---|---|
| (2, 2) | equal | check outer and inner |
| outer: (2.left = null, 2.right = 3) | one null | **false** |

## Complexity

- **Time: O(n)**: each node is compared once.
- **Space: O(h)** recursion (or O(w) with a BFS queue of pairs).

## Iterative version

Use a queue of pairs. Start with `(root.left, root.right)`. Pop a pair; if both null, continue; if one null or values differ, return false; otherwise push `(a.left, b.right)` and `(a.right, b.left)`.

## Common mistakes

- Comparing `a.left` with `b.left` (that checks equality, not mirroring).
- The traversal-sequence trick: "in-order equals its reverse" gives **false positives**, because different shapes can produce the same sequence. It only works if you also record nulls.

## Follow-ups

1. **Same Tree (LeetCode #100):** compare `a.left` with `b.left`.
2. **Invert Binary Tree (medium 21):** a tree is symmetric iff it equals its own inversion.
3. **LeetCode #101:** identical.

## What to remember

Mirror comparison pairs outer with outer and inner with inner. Handle all null cases first.
