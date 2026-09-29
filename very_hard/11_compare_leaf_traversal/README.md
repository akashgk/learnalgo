# Compare Leaf Traversal

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Lockstep lazy traversal (generators or explicit stacks)

## The problem

Given two binary trees, return whether their **leaves**, read from left to right, form the same sequence. The trees may have different shapes.

```
tree 1:        1                 tree 2:        1
             /   \                            /   \
            2     3                          2     3
           / \     \                        / \     \
          4   5     6                      4   7     5
             / \                                    / \
            7   8                                  8   6

leaves: 4, 7, 8, 6                 leaves: 4, 7, 8, 6      ->  true
```

## Step 1: Simple approach

Collect each tree's leaves into a list (DFS, left before right) and compare the lists. **O(n + m) time, O(n + m) space.** It cannot stop early: even if the first leaves differ, both trees are fully traversed.

## Step 2: Lockstep traversal

Produce leaves **on demand**, one at a time from each tree, and compare them pairwise. Stop at the first mismatch. Each tree only needs its traversal stack: **O(h1 + h2) space**.

## Step 3: Generators make this clean

A Dart `sync*` function returns a lazy `Iterable`: its body runs only until the next `yield`, then pauses. So a leaf generator is just an iterative DFS that `yield`s at each leaf. Two iterators are then advanced in lockstep with `moveNext()`.

(In Java you would write an `Iterator` class holding the stack; in Python a generator with `yield`.)

At the end, both iterators must run out **at the same time**; if one tree has extra leaves, the sequences differ.

## Step 4: The code

<!-- CODE:START -->

Full source: [`compare_leaf_traversal.dart`](compare_leaf_traversal.dart) (run it with `dart run`).

```dart
// Compare Leaf Traversal: do two binary trees have the same leaves, left to right?
// Walk both trees' leaves lazily in lockstep with explicit stacks.
// O(n + m) time, O(h1 + h2) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

bool compareLeafTraversal(BinaryTree tree1, BinaryTree tree2) {
  final a = _leaves(tree1).iterator, b = _leaves(tree2).iterator;
  while (true) {
    final hasA = a.moveNext(), hasB = b.moveNext();
    if (!hasA || !hasB) return hasA == hasB; // both must end together
    if (a.current != b.current) return false;
  }
}

/// Lazily yields leaf values in left-to-right order using an explicit stack.
Iterable<int> _leaves(BinaryTree root) sync* {
  final stack = [root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    if (node.left == null && node.right == null) {
      yield node.value;
      continue;
    }
    if (node.right case final r?) stack.add(r); // push right first so left is processed first
    if (node.left case final l?) stack.add(l);
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `_leaves(root)` is an iterative DFS: pop a node; if it is a leaf, `yield` its value; otherwise push the right child and then the left child (so the left is processed first).
- `compareLeafTraversal` advances both iterators together. `hasA == hasB` at the end checks that both finished together.

## Step 5: Dry run

| step | leaf from tree 1 | leaf from tree 2 | equal? |
|---|---|---|---|
| 1 | 4 | 4 | yes |
| 2 | 7 | 7 | yes |
| 3 | 8 | 8 | yes |
| 4 | 6 | 6 | yes |
| 5 | (none) | (none) | both finished: true |

## Complexity

- **Time: O(n + m)** in the worst case, with early exit on the first mismatch.
- **Space: O(h1 + h2)** for the two stacks.

## Alternative (AlgoExpert's O(h) approach)

Link each tree's leaves into a linked list during a traversal (reusing `right` pointers of the leaves), then compare the two lists. Also O(h) extra space, but it **mutates** the trees; the generator version does not.

## Common mistakes

- Treating a node with one child as a leaf.
- Only comparing up to the shorter sequence.

## Follow-ups

1. **Leaf-Similar Trees (LeetCode #872):** identical.
2. **Same fringe problem:** a classic example used to illustrate coroutines and generators.
3. **Compare two BSTs' sorted sequences** with two lazy in-order iterators (BST Iterator, #173).

## What to remember

To compare two traversals without materializing them, produce elements lazily (generators or iterator classes with an explicit stack) and advance them in lockstep.
