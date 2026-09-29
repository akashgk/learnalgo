# Iterative In-order Traversal

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Stackless traversal using parent pointers

## The problem

Each node of a binary tree has a pointer to its **parent**. Perform an **in-order** traversal (left subtree, node, right subtree), calling a callback on each node, **iteratively** and with **O(1) extra space**: no recursion, no stack.

```
        1
      /   \
     2     3
    /     / \
   4     6   7
    \
     9

in-order: 4, 9, 2, 1, 6, 3, 7
```

## Step 1: Why stacks are normally needed

A recursive or stack-based traversal remembers "where to return to" after finishing a subtree. That memory is O(h). Parent pointers give us that information for free: from any node we can always go back up.

## Step 2: The missing information: where did I come from?

When the walk arrives at a node, what to do next depends on **where it arrived from**. Keep a `previous` pointer:

1. **From the parent** (or starting at the root): the node's left subtree has not been visited.
   - If there is a left child: go left.
   - Otherwise the left subtree is (trivially) done: **visit** the node, then go right if possible, else go up.
2. **From the left child:** the left subtree is finished: **visit** the node, then go right if possible, else go up.
3. **From the right child:** both subtrees are finished: go up.

The traversal ends when you go up from the root (the next node is null).

## Step 3: The code

<!-- CODE:START -->

Full source: [`iterative_in_order_traversal.dart`](iterative_in_order_traversal.dart) (run it with `dart run`).

```dart
// Iterative In-order Traversal with parent pointers and O(1) extra space.
// Track the previous node to know whether we came from the parent, the left child, or the right.
// O(n) time, O(1) space.

class BinaryTree {
  BinaryTree(this.value, {this.left, this.right, this.parent});
  int value;
  BinaryTree? left;
  BinaryTree? right;
  BinaryTree? parent;
}

void iterativeInOrderTraversal(BinaryTree tree, void Function(BinaryTree) callback) {
  BinaryTree? previous;
  BinaryTree? current = tree;
  while (current != null) {
    BinaryTree? next;
    if (previous == null || identical(previous, current.parent)) {
      // Arrived from above: go left if possible; otherwise visit and go right or up.
      if (current.left != null) {
        next = current.left;
      } else {
        callback(current);
        next = current.right ?? current.parent;
      }
    } else if (identical(previous, current.left)) {
      // Left subtree done: visit, then go right or up.
      callback(current);
      next = current.right ?? current.parent;
    } else {
      // Right subtree done: go up.
      next = current.parent;
    }
    previous = current;
    current = next;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `previous` and `current` describe the last move.
- The three branches implement the three cases above.
- `previous = current; current = next;` makes the move.
- The test helper `node(...)` builds nodes and sets parent pointers.

## Step 4: Dry run (first steps)

| current | came from | action | callback |
|---|---|---|---|
| 1 | (start) | has left: go to 2 | |
| 2 | parent | has left: go to 4 | |
| 4 | parent | no left: visit, go right to 9 | 4 |
| 9 | parent | no left: visit, no right: go up | 9 |
| 4 | right child | go up | |
| 2 | left child | visit, no right: go up | 2 |
| 1 | left child | visit, go right to 3 | 1 |
| 3 | parent | go left to 6 | |
| 6 | parent | visit, go up | 6 |
| 3 | left child | visit, go right to 7 | 3 |
| 7 | parent | visit, go up | 7 |
| 3 | right child | go up; 1: from right child, go up; null: done | |

Output: `4, 9, 2, 1, 6, 3, 7`.

## Complexity

- **Time: O(n)**: every edge is traversed twice (once down, once up).
- **Space: O(1)**.

## Common mistakes

- Comparing nodes by value instead of identity.
- Forgetting the "no left child" sub-case in case 1 (the node would never be visited).

## Related techniques

- **Explicit stack in-order** (O(h) space): push lefts, pop, visit, go right. Know it by heart.
- **Morris traversal** (O(1) space, no parent pointers): temporarily point each node's in-order predecessor's right pointer back to it, and restore it on the second visit. The LeetCode #94 follow-up.

## What to remember

With parent pointers, a traversal needs only the previous node: whether you came from the parent, the left child, or the right child tells you exactly what to do next.
