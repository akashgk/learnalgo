# Flatten Binary Tree

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Bottom-up recursion returning list endpoints

## The problem

Flatten a binary tree **in place** into a doubly linked list ordered by **in-order** traversal: each node's `left` points to the previous node and `right` to the next one. Return the leftmost node (the head of the list).

```
          1
        /   \
       2     3
      / \   /
     4   5 6
        / \
       7   8

->  4 <-> 2 <-> 7 <-> 5 <-> 8 <-> 1 <-> 6 <-> 3
```

## Step 1: Simple approach with extra space

Traverse in-order into an array of nodes, then link each node with its neighbors. **O(n) time, O(n) space.** Correct; the in-place version saves the array.

## Step 2: Think recursively about one node

After flattening, a subtree becomes a list that runs from its **leftmost** to its **rightmost** node. Suppose the recursion flattens the left and right subtrees of `node` and tells us each list's two ends. Then `node` only needs to be spliced in the middle:

```
[left list first ... left list last] <-> node <-> [right list first ... right list last]
```

- `leftLast.right = node; node.left = leftLast`
- `node.right = rightFirst; rightFirst.left = node`

The flattened list of `node`'s subtree then runs from `leftFirst` (or `node` if there is no left subtree) to `rightLast` (or `node`).

So each call returns a pair `(first, last)`.

## Step 3: Order of operations

Recurse into a child **before** overwriting the pointer to it, otherwise you lose the child. In the code, `node.left case final l?` binds the child to `l` first, then the recursion runs on `l`, and only then are the pointers rewired.

## Step 4: The code

<!-- CODE:START -->

Full source: [`flatten_binary_tree.dart`](flatten_binary_tree.dart) (run it with `dart run`).

```dart
// Flatten Binary Tree into a doubly linked list in in-order order, in place:
// left = previous node, right = next node. Return the leftmost node.
// Recursive, each call returns its flattened (leftmost, rightmost). O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

BinaryTree flattenBinaryTree(BinaryTree root) => _flatten(root).$1;

(BinaryTree, BinaryTree) _flatten(BinaryTree node) {
  var leftmost = node, rightmost = node;
  if (node.left case final l?) {
    final (lFirst, lLast) = _flatten(l);
    lLast.right = node;
    node.left = lLast;
    leftmost = lFirst;
  }
  if (node.right case final r?) {
    final (rFirst, rLast) = _flatten(r);
    node.right = rFirst;
    rFirst.left = node;
    rightmost = rLast;
  }
  return (leftmost, rightmost);
}
```

<!-- CODE:END -->

### Walkthrough

- `_flatten` returns a record `(leftmost, rightmost)` of the flattened subtree.
- For a left child: flatten it, link its last node to `node`.
- For a right child: flatten it, link `node` to its first node.
- `flattenBinaryTree` returns `.$1`, the leftmost node.

## Step 5: Dry run (bottom-up)

| subtree | flattened list | returns (first, last) |
|---|---|---|
| 4 | 4 | (4, 4) |
| 7, 8 | single nodes | (7, 7), (8, 8) |
| 5 | 7 <-> 5 <-> 8 | (7, 8) |
| 2 | 4 <-> 2 <-> 7 <-> 5 <-> 8 | (4, 8) |
| 6 | 6 | (6, 6) |
| 3 | 6 <-> 3 | (6, 3) |
| 1 | 4 <-> 2 <-> 7 <-> 5 <-> 8 <-> 1 <-> 6 <-> 3 | (4, 3) |

The test also walks the list backward (via `left`) to confirm the links in both directions.

## Complexity

- **Time: O(n)**.
- **Space: O(h)** recursion.

## Common mistakes

- Overwriting `node.left` / `node.right` before recursing into the children.
- Returning only the head (the parent then cannot find the tail without walking the list, which makes it O(n^2)).

## Follow-ups

1. **Convert BST to Sorted Doubly Linked List (LeetCode #426):** the same, usually circular (link the last node back to the first).
2. **Flatten Binary Tree to Linked List (#114):** **pre-order**, using only `right` pointers. A different problem; read which order is required.

## What to remember

When a recursive transformation builds a list or chain, return both of its ends so the parent can splice in O(1).
