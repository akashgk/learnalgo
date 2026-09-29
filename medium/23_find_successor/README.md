# Find Successor

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Structural case analysis with parent pointers

## The problem

Each node in a binary tree has a pointer to its **parent**. Given the root and a node in the tree, return the node's **in-order successor**: the node visited right after it in an in-order traversal. Return null if it is the last.

```
          1
        /   \
       2     3
      / \
     4   5
    /
   6

in-order: 6, 4, 2, 5, 1, 3
successor(5) = 1,  successor(2) = 5,  successor(6) = 4,  successor(3) = null
```

## Step 1: Brute force

Do an in-order traversal into a list, find the node, return the next element. **O(n)** time and space. It works on any binary tree and ignores the parent pointers.

## Step 2: Think about what in-order does

In-order is "left subtree, node, right subtree". After visiting node X, what comes next?

**Case 1: X has a right subtree.** In-order visits X's right subtree immediately after X, starting from its **leftmost** node. So: go right once, then left as far as possible.

- successor(2): 2 has right child 5; 5 has no left child: successor is 5.

**Case 2: X has no right subtree.** X's whole subtree is finished. Climb upward:

- If you come up **from a right child**, that parent's subtree is also finished (the parent was visited before its right subtree): keep climbing.
- The first time you come up **from a left child**, that parent has not been visited yet (a parent is visited after its left subtree): it is the successor.
- If you reach the root without that happening, X was the last node: null.

Examples:
- successor(5): 5 is the right child of 2 (keep climbing), 2 is the left child of 1: successor is 1.
- successor(6): 6 is the left child of 4: successor is 4.
- successor(3): 3 is the right child of 1, and 1 has no parent: null.

## Step 3: The code

<!-- CODE:START -->

Full source: [`find_successor.dart`](find_successor.dart) (run it with `dart run`).

```dart
// Find Successor (in-order) in a binary tree with parent pointers.
// Case 1: right subtree exists -> leftmost node of it.
// Case 2: otherwise climb until we arrive from a left child. O(h) time, O(1) space.

class BinaryTree {
  BinaryTree(this.value, {this.left, this.right, this.parent});
  int value;
  BinaryTree? left;
  BinaryTree? right;
  BinaryTree? parent;
}

BinaryTree? findSuccessor(BinaryTree tree, BinaryTree node) {
  if (node.right case final right?) {
    var current = right;
    while (current.left != null) {
      current = current.left!;
    }
    return current;
  }
  var current = node;
  while (current.parent != null && identical(current.parent!.right, current)) {
    current = current.parent!;
  }
  return current.parent;
}
```

<!-- CODE:END -->

### Walkthrough

- `if (node.right case final right?)` handles Case 1: walk to the leftmost node of the right subtree.
- Case 2: `while (current.parent != null && identical(current.parent!.right, current))` climbs while we are a right child. `identical` compares node identity, not values.
- `return current.parent;` is the first ancestor reached from a left child, or null when we climbed past the root.

## Step 4: Dry run: successor(5)

| current | parent | current is parent's right child? | action |
|---|---|---|---|
| 5 | 2 | yes | climb |
| 2 | 1 | no (left child) | stop |

Return 1.

## Complexity

- **Time: O(h)**: at most one walk down (Case 1) or one walk up (Case 2).
- **Space: O(1)**.

## Common mistakes

- In Case 1, returning the right child itself instead of its leftmost descendant.
- In Case 2, returning the parent immediately without checking which side you came from.
- Comparing by value instead of identity (values may repeat).

## Follow-ups

1. **Successor in a BST without parent pointers (LeetCode #285):** walk down from the root; whenever you go left from a node, that node is a candidate successor (the last candidate is the answer). O(h).
2. **Predecessor:** mirror everything (left <-> right).
3. **LeetCode #510 (Inorder Successor in BST II):** exactly this problem.

## What to remember

For "what comes next in a traversal", split into structural cases (has a right subtree / does not) and reason from the traversal's definition.
