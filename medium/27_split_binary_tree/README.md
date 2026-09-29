# Split Binary Tree

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Subtree sums (post-order)

## The problem

Given a binary tree of integers (values may be negative), determine whether removing **one edge** splits it into two trees with equal sums. If so, return that sum; otherwise return 0.

```
            1
         /     \
        3       -2
       /       /  \
      6       5    2
     / \     /
    2  -5   2

total = 1 + 3 + 6 + 2 - 5 - 2 + 5 + 2 + 2 = 14
cut the edge above -2: the subtree {-2, 5, 2, 2} sums to 7, the rest sums to 7  ->  7
```

## Step 1: Work an example by hand

Removing an edge detaches exactly one subtree: the one below the edge. If that subtree sums to `S`, the rest sums to `total - S`. The halves are equal exactly when `S = total / 2`.

So the question becomes: **is there a subtree (not the whole tree) whose sum is `total / 2`?**

If `total` is odd, the answer is immediately 0.

## Step 2: The approach

1. Compute `total` with one traversal.
2. Traverse again in **post-order**, computing each subtree's sum from its children's sums. If any subtree other than the root's sums to `total / 2`, a valid cut exists.

Why exclude the root? The root's subtree is the whole tree, which is not the result of removing an edge. This matters when `total == 0`: the root would trivially "match" `0 / 2`.

Why not prune early? With negative values, a partial sum that exceeds `total / 2` can come back down, so every subtree must be computed.

## Step 3: The code

<!-- CODE:START -->

Full source: [`split_binary_tree.dart`](split_binary_tree.dart) (run it with `dart run`).

```dart
// Split Binary Tree: can removing one edge split the tree into two trees of equal sum?
// Return that sum, or 0. Compute total, then look for a proper subtree summing to total / 2.
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int splitBinaryTree(BinaryTree tree) {
  int sum(BinaryTree? t) => t == null ? 0 : t.value + sum(t.left) + sum(t.right);
  final total = sum(tree);
  if (total.isOdd) return 0;
  final half = total ~/ 2;
  var found = false;

  int visit(BinaryTree? t) {
    if (t == null) return 0;
    final s = t.value + visit(t.left) + visit(t.right);
    if (s == half && !identical(t, tree)) found = true; // the whole tree is not a split
    return s;
  }

  visit(tree);
  return found ? half : 0;
}
```

<!-- CODE:END -->

### Walkthrough

- `sum` is a nested recursive helper for the total.
- `if (total.isOdd) return 0;` is the early exit.
- `visit` returns each subtree's sum (post-order: children first).
- `if (s == half && !identical(t, tree)) found = true;` records a valid cut, excluding the root.
- `return found ? half : 0;`

## Step 4: Dry run (subtree sums, bottom-up)

| subtree root | sum |
|---|---|
| 2 (under 6) | 2 |
| -5 | -5 |
| 6 | 6 + 2 - 5 = 3 |
| 3 | 3 + 3 = 6 |
| 2 (under 5) | 2 |
| 5 | 7 |
| 2 (right of -2) | 2 |
| -2 | -2 + 7 + 2 = **7** = half |
| 1 (root) | 1 + 6 + 7 = 14 |

A non-root subtree sums to 7: return 7.

## Complexity

- **Time: O(n)**: two traversals.
- **Space: O(h)**.

## Edge cases

- Odd total: 0.
- Single node: there is no edge to remove: 0.
- Total 0 with a valid split: returns 0, which is **indistinguishable** from "no split". That is a flaw in the problem's return format; mention it in an interview. LeetCode #663 returns a boolean to avoid it.

## Common mistakes

- Counting the whole tree as a split.
- Pruning when a partial sum exceeds half (wrong with negative values).

## Follow-ups

1. **Equal Tree Partition (LeetCode #663).**
2. **Maximum Product of Splitted Binary Tree (#1339):** compute all subtree sums, maximize `S * (total - S)`.
3. **One pass instead of two:** store all subtree sums in a list during a single post-order pass (the root's sum is the total), then check the list. Same complexity.

## What to remember

"Remove one edge" = "detach one subtree". Compute all subtree sums bottom-up and test each against the target.
