# Right Sibling Tree

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** In-place pointer rewiring with a carefully chosen order

## The problem

Transform a binary tree in place so that every node's `right` pointer points to its **right sibling** instead of its right child. Left pointers are unchanged. Following AlgoExpert's definition:

- the root's right pointer becomes null;
- a **left child's** right sibling is its parent's (original) right child;
- a **right child's** right sibling is the **left child of its parent's right sibling** (null if either is missing).

```
              1                              1
          /       \                         /
         2         3                       2 ------------ 3
       /   \     /   \                    /              /
      4     5   6     7        ->        4 ---- 5 ----- 6 ---- 7
     / \     \  /    / \                /        \     /      /
    8   9   10 11   12  13             8 - 9    10 - 11     12 - 13
               /                                   /
              14                                  14
```

9 points to null because 5 (its parent's sibling) has no left child.

## Step 1: The difficulty

We overwrite `right`, but `right` is also how we reach the right child. After rewiring a node, its right child is no longer reachable through it. So the **order** of operations is the whole problem.

## Step 2: Choose the order

Save `left` and `right` in local variables first. Then:

1. **Recurse into the left child** while the current node's `right` still points to its **original** right child. The left child needs exactly that pointer: its sibling is `parent.right` (original).
2. **Rewire the current node.**
3. **Recurse into the right child.** By now the parent has been rewired, so `parent.right` points to the **parent's sibling**. The right child needs exactly that: its sibling is `parent.right.left`.

Why is `parent.right.left` still valid? Only `right` pointers are ever changed; `left` pointers keep pointing to the original left children.

## Step 3: The code

<!-- CODE:START -->

Full source: [`right_sibling_tree.dart`](right_sibling_tree.dart) (run it with `dart run`).

```dart
// Right Sibling Tree: rewire every node's `right` pointer to its right neighbor on the same
// level (null at the end of a level), for a tree where the level structure is determined by the
// original tree. In place, no queue. O(n) time, O(d) space (recursion).
//
// Order matters: a left child reads its parent's ORIGINAL right child, so the parent must be
// rewired only after its left subtree is done; a right child reads its parent's NEW right
// pointer (the parent's sibling), so the parent must be rewired before its right subtree.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree rightSiblingTree(BinaryTree root) {
  _mutate(root, null, false);
  return root;
}

void _mutate(BinaryTree? node, BinaryTree? parent, bool isLeftChild) {
  if (node == null) return;
  final left = node.left, right = node.right;
  _mutate(left, node, true);
  if (parent == null) {
    node.right = null;
  } else if (isLeftChild) {
    node.right = parent.right; // parent not rewired yet: this is my sibling
  } else {
    node.right = parent.right?.left; // parent.right is now the parent's right neighbor
  }
  _mutate(right, node, false);
}

List<int> chain(BinaryTree start) => [for (BinaryTree? n = start; n != null; n = n.right) n.value];
```

<!-- CODE:END -->

### Walkthrough

- `_mutate(node, parent, isLeftChild)` receives the parent and which side the node is on.
- `left` and `right` are saved before anything changes.
- Root: `node.right = null`. Left child: `node.right = parent.right` (original). Right child: `node.right = parent.right?.left` (parent already rewired).
- The test builds the tree and checks every level's chain of `right` pointers.

## Step 4: Dry run (key nodes)

| node | side | parent.right at that moment | new right |
|---|---|---|---|
| 1 | root | | null |
| 2 | left of 1 | 3 (original) | 3 |
| 4 | left of 2 | 5 (original) | 5 |
| 8 | left of 4 | 9 (original) | 9 |
| 9 | right of 4 | 4 already rewired: 5 | 5.left = null |
| 5 | right of 2 | 2 rewired: 3 | 3.left = 6 |
| 10 | right of 5 | 5 rewired: 6 | 6.left = 11 |
| 6 | left of 3 | 7 (original) | 7 |
| 11 | left of 6 | 6's original right: null | null |

## Complexity

- **Time: O(n)**.
- **Space: O(d)** recursion depth.

## LeetCode's version is different

**Populating Next Right Pointers (LeetCode #116/#117)** links **every** node to the next node on the same level (so 9 would point to 10). There, use the already-built `next` pointers of the level above to walk across it: O(1) extra space and a completely different technique. Always confirm the definition.

## Common mistakes

- Recursing into the right child before rewiring the current node (the right child then reads the original right pointer, which is itself).
- Overwriting `right` before saving it.

## What to remember

For in-place pointer rewiring, list which pointers each step reads and writes, then order the recursion so every read happens while the pointer still has the value you need.
