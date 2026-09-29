# All Kinds Of Node Depths

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Bottom-up aggregation with subtree sizes

## The problem

For **every** node in a binary tree, treat that node as the root of its own subtree and compute the sum of the depths of all nodes in that subtree (as in Node Depths, easy 09). Return the **sum of all these values**.

```
         1
       /   \
      2     3
     / \   / \
    4   5 6   7
   / \
  8   9          ->  26
```

- Subtree of 1: depths sum to 16 (the Node Depths answer).
- Subtree of 2: 4 and 5 at depth 1, 8 and 9 at depth 2: 6.
- Subtree of 3: 2. Subtree of 4: 2. Leaves: 0.
- Total: 16 + 6 + 2 + 2 = 26.

## Step 1: Brute force

Run Node Depths from every node: O(size of subtree) each. Total O(n log n) for balanced trees, **O(n^2)** for skewed trees.

## Step 2: How a subtree's depth sum relates to its children's

Let `D(t)` = the sum of depths in `t`'s subtree, measured from `t`, and `S(t)` = the number of nodes in the subtree.

Every node in the left child's subtree is **one level deeper** when measured from `t` than when measured from the left child. There are `S(left)` of them, so:

```
D(t) = D(left) + S(left) + D(right) + S(right)
S(t) = 1 + S(left) + S(right)
```

Both are computed bottom-up in O(1) per node. The requested answer is the sum of `D(t)` over all nodes, also accumulated bottom-up.

## Step 3: A second, independent derivation

Look at a single node at depth `d` (from the real root). It is counted in the subtree of each of its ancestors, and of itself, with depths `d, d - 1, ..., 1, 0`. Its total contribution is `0 + 1 + ... + d = d(d + 1) / 2`. So the answer is also `sum over all nodes of d(d + 1) / 2`: a single top-down traversal. For the example: depths 0; 1, 1; 2, 2, 2, 2; 3, 3 give `0 + 1 + 1 + 3*4 + 6*2 = 26`.

Two very different routes to the same number: either is a strong answer, and knowing both shows real understanding.

## Step 4: The code

<!-- CODE:START -->

Full source: [`all_kinds_of_node_depths.dart`](all_kinds_of_node_depths.dart) (run it with `dart run`).

```dart
// All Kinds Of Node Depths: sum, over every node, of the node depths in its subtree.
// Bottom-up: depthSum(node) = sum over children of (depthSum(child) + size(child)).
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int allKindsOfNodeDepths(BinaryTree root) => _info(root).total;

({int size, int depthSum, int total}) _info(BinaryTree? t) {
  if (t == null) return (size: 0, depthSum: 0, total: 0);
  final l = _info(t.left), r = _info(t.right);
  // Every node in a child's subtree is one level deeper when measured from t.
  final depthSum = l.depthSum + l.size + r.depthSum + r.size;
  return (size: 1 + l.size + r.size, depthSum: depthSum, total: depthSum + l.total + r.total);
}
```

<!-- CODE:END -->

### Walkthrough

- `_info(t)` returns a record `(size, depthSum, total)` for t's subtree.
- `depthSum = l.depthSum + l.size + r.depthSum + r.size` is the relation from Step 2.
- `total = depthSum + l.total + r.total` adds this node's value to the totals of its subtrees.

## Step 5: Dry run (bottom-up)

| node | size | depthSum D | total |
|---|---|---|---|
| 8, 9 | 1 | 0 | 0 |
| 4 | 3 | 0 + 1 + 0 + 1 = 2 | 2 |
| 5 | 1 | 0 | 0 |
| 2 | 5 | 2 + 3 + 0 + 1 = 6 | 6 + 2 + 0 = 8 |
| 6, 7 | 1 | 0 | 0 |
| 3 | 3 | 2 | 2 |
| 1 | 9 | 6 + 5 + 2 + 3 = 16 | 16 + 8 + 2 = **26** |

## Complexity

- **Time: O(n)**.
- **Space: O(h)**.

## Common mistakes

- Forgetting the `+ size` terms (each subtree gets one level deeper at the parent).
- Adding the root's depth sum only.

## Follow-ups

1. **Sum of Distances in Tree (LeetCode #834):** distances from every node to **all** other nodes, not just its subtree. Needs a second top-down "rerooting" pass: `answer(child) = answer(parent) - size(child) + (n - size(child))`.
2. **Node Depths (easy 09):** the single-root version.

## What to remember

When a quantity for a node can be expressed with its children's quantities plus their sizes, compute everything bottom-up in one pass.
