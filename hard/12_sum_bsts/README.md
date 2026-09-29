# Sum BSTs

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** Bottom-up DFS returning subtree summaries

## The problem

Given a binary tree, find every subtree that is a valid BST **with at least 3 nodes**, and return the sum of their sizes. If a BST subtree is contained inside a larger BST subtree, only the larger one is counted (no node is counted twice). Duplicates go to the right (right subtree values are `>=` the node).

```
            8
         /     \
        2       9
      /   \    / \
     1    10  5   15
         /  \      \
        5    15     22

Subtree at 2:  {1, 2, 5, 10, 15} is a BST of size 5  (it contains the BST at 10, counted once)
Subtree at 9:  {5, 9, 15, 22} is a BST of size 4
Whole tree:    not a BST (10 and 15 are in 8's left subtree)
Answer: 5 + 4 = 9
```

> Definition note: this follows AlgoExpert's reference behavior as I recall it (a counted BST replaces its children's totals). The statement is paywalled, so verify the wording if you practice on the site. The variant "count nested BSTs too" is a one-line change, shown below.

## Step 1: Brute force

For every node, check whether its subtree is a BST (O(size)) and compute its size. Summed over all nodes: O(n^2) on skewed trees.

## Step 2: What does a node need from its children?

Whether the subtree at `t` is a BST depends on:

- both child subtrees being BSTs;
- every value in the left subtree being `< t.value`: the left subtree's **maximum** `< t.value`;
- every value in the right subtree being `>= t.value`: the right subtree's **minimum** `>= t.value`.

So each subtree should report: `isBst`, `min`, `max`, `size`, and the running answer `total` for that subtree. The parent combines its children's reports in O(1). This is the bottom-up "return a tuple" technique from Binary Tree Diameter, with more fields.

**Null subtrees** report `isBst = true`, `min = +infinity`, `max = -infinity`, size 0, total 0. With those neutral values, the comparisons `leftMax < value <= rightMin` pass automatically for missing children.

## Step 3: Combining at node t

```
isBst = left.isBst and right.isBst and left.max < t.value <= right.min
size  = isBst ? 1 + left.size + right.size : 0
total = (isBst and size >= 3) ? size : left.total + right.total
min   = min(t.value, left.min, right.min)
max   = max(t.value, left.max, right.max)
```

The `total` rule implements "count the largest BST only": if the whole subtree at `t` is a counted BST, its size **replaces** its children's totals.

## Step 4: The code

<!-- CODE:START -->

Full source: [`sum_bsts.dart`](sum_bsts.dart) (run it with `dart run`).

```dart
// Sum BSTs: sum of the sizes of all maximal BST subtrees with at least 3 nodes.
// If a subtree is a BST (>= 3 nodes), count it once and do not add its nested BST subtrees.
// Post-order with per-subtree info. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

typedef _Info = ({bool isBst, int min, int max, int size, int total});

int sumBsts(BinaryTree tree) => _info(tree).total;

_Info _info(BinaryTree? t) {
  if (t == null) {
    return (isBst: true, min: 1 << 62, max: -(1 << 62), size: 0, total: 0);
  }
  final l = _info(t.left), r = _info(t.right);
  // Duplicates go right: left values strictly less, right values >= node.
  final isBst = l.isBst && r.isBst && l.max < t.value && t.value <= r.min;
  final size = isBst ? 1 + l.size + r.size : 0;
  final total = isBst && size >= 3 ? size : l.total + r.total;
  return (
    isBst: isBst,
    min: [t.value, l.min, r.min].reduce((a, b) => a < b ? a : b),
    max: [t.value, l.max, r.max].reduce((a, b) => a > b ? a : b),
    size: size,
    total: total,
  );
}
```

<!-- CODE:END -->

### Walkthrough

- `typedef _Info = ({bool isBst, int min, int max, int size, int total});` names the record type returned by each call.
- The null case uses `1 << 62` and `-(1 << 62)` as infinities.
- The rest is the combination from Step 3.

## Step 5: Dry run (bottom-up, selected nodes)

| node | isBst | size | total |
|---|---|---|---|
| 5 (under 10) | yes | 1 | 0 |
| 15 (under 10) | yes | 1 | 0 |
| 10 | yes (5 < 10 <= 15) | 3 | 3 |
| 1 | yes | 1 | 0 |
| 2 | yes (1 < 2 <= 5) | 5 | **5** (replaces 3) |
| 22 | yes | 1 | 0 |
| 15 (under 9) | yes | 2 | 0 (size < 3) |
| 5 (under 9) | yes | 1 | 0 |
| 9 | yes (5 < 9 <= 15) | 4 | **4** |
| 8 | no (left max 15 > 8) | 0 | 5 + 4 = **9** |

## Complexity

- **Time: O(n)**.
- **Space: O(h)**.

## Variant: count nested BSTs separately

Change the total to `left.total + right.total + (isBst && size >= 3 ? size : 0)`. Always confirm with the interviewer which definition is intended.

## Common mistakes

- Checking only direct children instead of subtree min/max.
- Wrong neutral values for null children.

## Follow-ups

1. **Largest BST Subtree (LeetCode #333):** return the max size instead of a sum.
2. **Maximum Sum BST in Binary Tree (#1373):** return the max sum of a BST subtree.

## What to remember

For "which subtrees satisfy property P", return a summary record from each subtree (validity, min, max, size, running answer) and combine in O(1) per node.
