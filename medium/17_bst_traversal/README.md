# BST Traversal

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** The three depth-first orders

## The problem

Implement three functions that traverse a BST and append its values to a list:

- `inOrderTraverse`: left subtree, node, right subtree;
- `preOrderTraverse`: node, left subtree, right subtree;
- `postOrderTraverse`: left subtree, right subtree, node.

```
          10
        /    \
       5      15
      / \       \
     2   5       22
    /
   1

in-order:   [1, 2, 5, 5, 10, 15, 22]
pre-order:  [10, 5, 2, 1, 5, 15, 22]
post-order: [1, 2, 5, 5, 22, 15, 10]
```

## Step 1: The only difference is WHEN you visit the node

All three are the same depth-first walk. The code differs in exactly one line: whether `add(node.value)` comes before, between, or after the two recursive calls. Memorize them as "pre = node first, in = node in the middle, post = node last".

## Step 2: When to use which

| Order | Sequence | Typical uses | Repo examples |
|---|---|---|---|
| Pre-order | node, left, right | copy or serialize a tree; the root comes first so a rebuild can start from it | Reconstruct BST (medium 20), Branch Sums |
| In-order | left, node, right | on a BST, produces **sorted** values | Validate BST, Kth Largest, Repair BST |
| Post-order | left, right, node | when a node needs its children's results first: heights, sizes, deleting a tree, evaluating expressions | Evaluate Expression Tree, Binary Tree Diameter |

Why does in-order give sorted output on a BST? Everything in the left subtree is smaller than the node and everything in the right subtree is at least the node. Visiting "all smaller, then me, then all bigger", recursively, is exactly sorted order.

## Step 3: The code

<!-- CODE:START -->

Full source: [`bst_traversal.dart`](bst_traversal.dart) (run it with `dart run`).

```dart
// BST Traversal: in-order, pre-order, post-order. Each O(n) time, O(n) output, O(h) stack.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

List<int> inOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    inOrderTraverse(tree.left, a);
    a.add(tree.value);
    inOrderTraverse(tree.right, a);
  }
  return a;
}

List<int> preOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    a.add(tree.value);
    preOrderTraverse(tree.left, a);
    preOrderTraverse(tree.right, a);
  }
  return a;
}

List<int> postOrderTraverse(BST? tree, [List<int>? out]) {
  final a = out ?? <int>[];
  if (tree != null) {
    postOrderTraverse(tree.left, a);
    postOrderTraverse(tree.right, a);
    a.add(tree.value);
  }
  return a;
}
```

<!-- CODE:END -->

### Walkthrough

- Each function takes an optional `out` list. The first call creates it; recursive calls pass it along, so every value is appended to one shared list (O(n) total). Creating and concatenating new lists at each node would cost O(n^2) in the worst case.
- `if (tree != null)` is the base case: an empty subtree contributes nothing.

## Step 4: Dry run (in-order)

| call | action | output so far |
|---|---|---|
| in(10) -> in(5) -> in(2) -> in(1) | leftmost reached | [1] |
| back in 2 | visit 2 | [1, 2] |
| back in 5 | visit 5, go to right child 5 | [1, 2, 5, 5] |
| back in 10 | visit 10 | [1, 2, 5, 5, 10] |
| in(15) | left null, visit 15, go right | [..., 15] |
| in(22) | visit 22 | [1, 2, 5, 5, 10, 15, 22] |

## Complexity

- **Time: O(n)** for each traversal.
- **Space: O(n)** for the output; O(h) recursion stack.

## Iterative versions (be ready to write them)

**In-order with a stack:**

```
node = root
while node != null or stack not empty:
    while node != null: push node; node = node.left
    node = pop(); visit(node)
    node = node.right
```

**Pre-order:** push root; pop, visit, push right then left.

**Post-order:** the trick is to do a "node, right, left" pre-order and reverse the output, or use two stacks.

Very Hard 07 (Iterative In-order Traversal) does it with O(1) space using parent pointers. **Morris traversal** achieves O(1) space without parent pointers by temporarily threading the tree.

## Level-order (the fourth traversal)

Breadth-first: visit level by level with a queue (see Breadth-first Search, medium 37).

## What to remember

Pre, in, post differ only in where "visit node" sits relative to the two recursive calls. In-order on a BST = sorted.
