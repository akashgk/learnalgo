# BST Construction

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** BST insert / search / delete

## Problem
Implement a `BST` class with `insert`, `contains`, and `remove`. Values equal to a node go to its right subtree. `remove` deletes the first node found with the value and does nothing if the value is absent. Removing the only node of a single-node tree does nothing.

## Building up the logic
**Insert / contains:** walk down, going left if `value < node.value`, else right. Insert attaches a new leaf where the walk falls off the tree.

**Remove** has three cases, and interviewers expect you to enumerate them before coding:
1. **Leaf:** unlink it from its parent.
2. **One child:** link the parent directly to that child.
3. **Two children:** you cannot unlink it without orphaning a subtree. Replace its value with its **in-order successor** (the minimum of its right subtree), then delete that successor from the right subtree. The successor has no left child, so deleting it is case 1 or 2.

**Root special case:** the root has no parent to relink. Because callers hold a reference to the root object, this implementation copies the child's contents into the root instead of replacing it.

## Complexity
| Operation | Average (balanced) | Worst (skewed) | Space (iterative) |
|---|---|---|---|
| insert | O(log n) | O(n) | O(1) |
| contains | O(log n) | O(n) | O(1) |
| remove | O(log n) | O(n) | O(1) |

Recursive versions use O(h) stack space.

## Interview notes
- Worst case is O(n) because a plain BST is not self-balancing: inserting sorted data produces a linked list. Mention AVL / red-black trees (Java `TreeMap`, C++ `std::map`) as the fix. Dart's `SplayTreeMap` is a self-adjusting BST with amortized O(log n).
- Predecessor (max of left subtree) works equally well for the two-children case.
