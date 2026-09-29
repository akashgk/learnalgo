# BST Construction

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** BST insert / search / delete

## The problem

Implement a Binary Search Tree class with three methods:

- `insert(value)`: add a value (duplicates go to the **right** subtree);
- `contains(value)`: return whether the value is in the tree;
- `remove(value)`: remove the first node found with that value; do nothing if absent. A tree that has only its root keeps it (removing the only node does nothing).

**BST property:** every node's value is strictly greater than all values in its left subtree and less than or equal to all values in its right subtree.

```
insert 10, 5, 15, 2, 5, 13, 22, 1, 14, 12

            10
          /    \
         5      15
        / \    /  \
       2   5  13   22
      /      /  \
     1      12   14
```

## Step 1: How search works

To find 13: at 10, 13 is bigger, go right. At 15, 13 is smaller, go left. At 13: found. Each comparison discards an entire subtree. `insert` is the same walk: follow the comparisons until you fall off the tree, and attach the new node there.

## Step 2: insert and contains

```
insert(v):
    node = root
    loop:
        if v < node.value:  if no left child: attach here; else go left
        else:               if no right child: attach here; else go right

contains(v):
    node = root
    while node: if equal -> true; else go left or right
    return false
```

Iterative versions use O(1) extra space. Recursive versions are shorter but use O(h) stack.

## Step 3: remove, the real test

First find the node (and remember its parent). Then there are **three cases**. Enumerate them out loud before coding; interviewers look for that.

**Case 1: the node is a leaf.** Unlink it from its parent.

```
remove 1:      2          2
              /     ->
             1
```

**Case 2: the node has one child.** Link the parent directly to that child.

```
remove 13 if it had only child 14:   15            15
                                    /      ->     /
                                  13             14
                                    \
                                     14
```

**Case 3: the node has two children.** You cannot unlink it without orphaning a subtree. Instead:

1. find its **in-order successor**: the smallest value in its right subtree (go right once, then left as far as possible);
2. copy that value into the node;
3. delete the successor from the right subtree.

The successor has no left child (it is the leftmost), so deleting it is always Case 1 or 2. Replacing with the successor keeps the BST property: it is bigger than everything on the left and at most everything else on the right.

```
remove 10:   successor = 12 (leftmost of right subtree)
            12
          /    \
         5      15
        / \    /  \
       2   5  13   22
      /          \
     1            14
```

**Special case: removing the root when it has fewer than two children.** The root has no parent to relink. Since callers hold a reference to the root object, this implementation copies the child's value and children into the root object instead of replacing it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`bst_construction.dart`](bst_construction.dart) (run it with `dart run`).

```dart
// BST Construction: insert, contains, remove (iterative).
// Average O(log n), worst O(n) time per operation; O(1) extra space.
// Duplicates go to the right subtree (right side holds values >= node).

class BST {
  BST(this.value);
  int value;
  BST? left;
  BST? right;

  BST insert(int value) {
    var node = this;
    while (true) {
      if (value < node.value) {
        if (node.left == null) {
          node.left = BST(value);
          return this;
        }
        node = node.left!;
      } else {
        if (node.right == null) {
          node.right = BST(value);
          return this;
        }
        node = node.right!;
      }
    }
  }

  bool contains(int value) {
    BST? node = this;
    while (node != null) {
      if (value == node.value) return true;
      node = value < node.value ? node.left : node.right;
    }
    return false;
  }

  /// Removes the first node found with [value]. A lone root is kept (a tree cannot be empty).
  BST remove(int value, [BST? parent]) {
    BST? node = this;
    while (node != null) {
      if (value < node.value) {
        parent = node;
        node = node.left;
      } else if (value > node.value) {
        parent = node;
        node = node.right;
      } else {
        if (node.left != null && node.right != null) {
          // Two children: copy the successor (min of right subtree), then delete it there.
          node.value = node.right!._minValue();
          node.right!.remove(node.value, node);
        } else if (parent == null) {
          // Root with at most one child: pull the child's contents up into the root object.
          final child = node.left ?? node.right;
          if (child != null) {
            node
              ..value = child.value
              ..left = child.left
              ..right = child.right;
          }
        } else {
          final child = node.left ?? node.right;
          if (identical(parent.left, node)) {
            parent.left = child;
          } else {
            parent.right = child;
          }
        }
        break;
      }
    }
    return this;
  }

  int _minValue() {
    var node = this;
    while (node.left != null) {
      node = node.left!;
    }
    return node.value;
  }

  List<int> inOrder() => [...?left?.inOrder(), value, ...?right?.inOrder()];
}
```

<!-- CODE:END -->

### Walkthrough

- `insert` returns `this` so calls can be chained (`bst.insert(1).insert(2)`), matching AlgoExpert's interface.
- `contains` walks down with a nullable `node` and stops at `null`.
- `remove(int value, [BST? parent])`: the optional `parent` lets the two-children case call `remove` on the right subtree while still knowing the parent to relink.
  - The first two branches walk down and track `parent`.
  - Two children: `node.value = node.right!._minValue(); node.right!.remove(node.value, node);`.
  - `parent == null` (root with at most one child): copy the child's contents into the root. If there is no child at all (a single-node tree), nothing happens, matching the problem's rule.
  - Otherwise: `identical(parent.left, node)` tells us which side to relink.
- `_minValue()` walks left to the smallest value.
- `inOrder()` is a test helper; in-order traversal of a BST is sorted, which the tests use to verify structure.

## Step 5: Dry run of `remove(10)` on the tree above

| step | action |
|---|---|
| find 10 | it is the root; `parent` is null |
| two children? | yes (5 and 15) |
| successor | right child 15 -> left 13 -> left 12 -> no left: successor is 12 |
| copy | root value becomes 12 |
| delete 12 from right subtree | walk 15 -> 13 -> 12, parent = 13; 12 is a leaf: `13.left = null` |

In-order result: `1, 2, 5, 5, 12, 13, 14, 15, 22`.

## Complexity

| Operation | Average (balanced) | Worst (skewed) | Space (iterative) |
|---|---|---|---|
| insert | O(log n) | O(n) | O(1) |
| contains | O(log n) | O(n) | O(1) |
| remove | O(log n) | O(n) | O(1) |

A plain BST does not rebalance: inserting sorted values (1, 2, 3, ...) creates a chain of height n. Self-balancing trees (AVL, red-black) guarantee O(log n); Java's `TreeMap` and C++'s `std::map` are red-black trees. Dart's `SplayTreeMap` is a self-adjusting tree with amortized O(log n).

## Common mistakes

- Forgetting the two-children case, or replacing with the successor without deleting the original successor node.
- Not handling root removal (no parent).
- Inconsistent duplicate handling (insert sends duplicates right, but search goes left on equality).

## Follow-ups

1. **Use the in-order predecessor instead of the successor** (largest in the left subtree): equally valid.
2. **k-th smallest, rank queries:** store subtree sizes in each node (an "order statistic tree").
3. **Delete Node in a BST (LeetCode #450):** the recursive version returning the new subtree root is shorter; be able to write both.

## What to remember

Search, insert and delete all walk one root-to-leaf path. Deletion has three cases: leaf, one child, two children (replace with the in-order successor, then delete that successor).
