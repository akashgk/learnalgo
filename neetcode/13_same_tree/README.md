# Same Tree

**Difficulty:** Easy | **Category:** Trees | **Pattern:** Simultaneous DFS on two trees | **Source:** LeetCode 100; NeetCode 150, Blind 75

## The problem

Return true if two binary trees have the same structure and the same values at every position.

```
  1       1
 / \     / \      ->  true
2   3   2   3

  1       1
 /         \      ->  false (same values, different shape)
2           2
```

## Step 1: Why comparing traversals is not enough

A **single** traversal without null markers does not determine a tree. In the second example, preorder gives `[1, 2]` for both trees, even though one has 2 on the left and the other on the right. So compare structurally, node by node.

## Step 2: Recursive definition

Two trees are the same when:

- both are empty, or
- both are non-empty, their roots have equal values, their left subtrees are the same, and their right subtrees are the same.

If exactly one is empty, they differ.

## Step 3: The code

<!-- CODE:START -->

Full source: [`same_tree.dart`](same_tree.dart) (run it with `dart run`).

```dart
// Same Tree: are two binary trees identical in shape and values?
// Simultaneous DFS: both null, or both present with equal values and equal subtrees.
// O(min(n, m)) time (stops at the first difference), O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

bool isSameTree(TreeNode? p, TreeNode? q) {
  if (p == null || q == null) return p == q; // equal only if both are null
  return p.value == q.value && isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
}
```

<!-- CODE:END -->

### Walkthrough

- `if (p == null || q == null) return p == q;` covers three cases in one line: both null (true), one null (false).
- `&&` short-circuits: the first difference stops the recursion.

## Step 4: Dry run

`[1, 2, 1]` vs `[1, 1, 2]` (root, left, right):

| call | values | result |
|---|---|---|
| roots | 1, 1 | equal, check left |
| left children | 2, 1 | **different**: false, right side never checked |

## Complexity

- Time: **O(min(n, m))**: stops at the first mismatch; O(n) when the trees are equal.
- Space: **O(h)** recursion.

## Edge cases

- Both empty: true.
- One empty: false.

## Common mistakes

- Comparing one traversal of each tree.
- Checking `p.value == q.value` before checking for null.

## Follow-ups you should be ready for

1. **Subtree of Another Tree.** Call this function from every node; see neetcode 14.
2. **Symmetric Tree.** Compare `left` with the mirror of `right`; see AlgoExpert medium 26 Symmetrical Tree.
3. **Iterative version.** A queue of node pairs.

## What to remember

Two trees are equal if their roots match and their subtrees match, recursively. Handle the null cases first.
