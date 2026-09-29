# Merge Binary Trees

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Traverse two trees in lockstep

## The problem

Given two binary trees, merge them into one: where both trees have a node in the same position, the merged node's value is the **sum** of the two values; where only one tree has a node, use that node (with its whole subtree). Return the merged tree. Modifying the first tree in place is allowed.

```
tree1:          tree2:           merged:
    1               1                2
   / \             / \              / \
  3   2           5   9            8   11
 / \             /   / \          / \  / \
7   4           2   7   6        9  4 7   6
```

## Step 1: Work an example by hand

Overlay the two trees. Position by position:

- root: 1 + 1 = 2;
- left child: 3 + 5 = 8; its left: 7 + 2 = 9; its right: 4 (only in tree1);
- right child: 2 + 9 = 11; its children 7 and 6 exist only in tree2, so they are taken from tree2.

You walked both trees **at the same time**, position by position. That is a paired recursion: `merge(a, b)` looks at two nodes in the same position.

## Step 2: The recursion

```
merge(a, b):
    if a is null: return b          # nothing to add; reuse b's whole subtree
    if b is null: return a
    a.value += b.value
    a.left  = merge(a.left,  b.left)
    a.right = merge(a.right, b.right)
    return a
```

The base cases carry the interesting logic: when one side is missing, the answer for this position is simply the other side's entire subtree, attached as is. No need to copy it node by node.

## Step 3: The code

<!-- CODE:START -->

Full source: [`merge_binary_trees.dart`](merge_binary_trees.dart) (run it with `dart run`).

```dart
// Merge Binary Trees: overlapping nodes are summed; otherwise the existing node is used.
// Merges into tree1 in place. O(n) time where n = nodes in the smaller overlap, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree? mergeBinaryTrees(BinaryTree? tree1, BinaryTree? tree2) {
  if (tree1 == null) return tree2;
  if (tree2 == null) return tree1;
  tree1.value += tree2.value;
  tree1.left = mergeBinaryTrees(tree1.left, tree2.left);
  tree1.right = mergeBinaryTrees(tree1.right, tree2.right);
  return tree1;
}

List<int?> preOrder(BinaryTree? t) => t == null ? [null] : [t.value, ...preOrder(t.left), ...preOrder(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- The two `if` lines are the base cases. Returning `tree2` attaches tree2's subtree into tree1's structure.
- `tree1.value += tree2.value;` merges the overlapping node.
- The recursive calls are assigned back into `tree1.left` / `tree1.right`, because a child that was null in tree1 may be replaced by tree2's subtree.
- `preOrder` (test helper) writes `null` for missing children so the test can compare exact shapes.

## Step 4: Dry run

| call | action |
|---|---|
| merge(1, 1) | value 2, recurse left and right |
| merge(3, 5) | value 8 |
| merge(7, 2) | value 9, children merge(null, null) -> null |
| merge(4, null) | return tree1's 4 |
| merge(2, 9) | value 11 |
| merge(null, 7) | return tree2's 7 |
| merge(null, 6) | return tree2's 6 |

## Complexity

- **Time: O(min(n1, n2))** roughly: recursion only continues where **both** trees have nodes. Subtrees that exist on one side only are attached in O(1).
- **Space: O(min(h1, h2))** recursion depth.

## Design note: mutating the input

This version modifies `tree1` and shares subtrees from `tree2`. That is efficient but means later changes to `tree2` would affect the merged tree. If inputs must stay untouched, create new nodes at every position (O(n1 + n2) time and space). State the choice in an interview.

## Common mistakes

- Forgetting to assign the recursive results back to `tree1.left/right`.
- Copying single-sided subtrees node by node (unnecessary work).

## Follow-ups

1. **Iterative version:** a stack of `(node1, node2)` pairs; when `node1.left` is null, attach `node2.left` directly.
2. **LeetCode #617:** identical.

## What to remember

For problems about two trees at once (same, mirror, merge), recurse on pairs of nodes in corresponding positions. The null cases usually hold the key logic.
