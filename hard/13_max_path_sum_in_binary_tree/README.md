# Max Path Sum In Binary Tree

**Difficulty:** Hard | **Category:** Binary Trees | **Pattern:** Bottom-up DFS: "branch" returned to the parent vs "bent path" recorded as a candidate

## The problem

A **path** in a binary tree is a sequence of connected nodes, each appearing at most once. It does not need to pass through the root and must contain at least one node. Values can be **negative**. Return the maximum sum of any path.

```
         1
       /   \
      2     3
     / \   / \
    4   5 6   7          ->  18   (5 -> 2 -> 1 -> 3 -> 7)

       -10
       /  \
      9    20
          /  \
         15   7          ->  42   (15 -> 20 -> 7)
```

## Step 1: Paths bend at one node

Every path has a unique **highest** node. The path comes up from one side of that node (or starts at it) and goes down the other side (or ends at it). In the second example the best path's highest node is 20: left branch 15, the node 20, right branch 7.

## Step 2: Two different quantities

At each node `t`, distinguish:

1. **branch(t):** the best sum of a path that **starts at t and goes straight down one side** (or is just `t`). This is what `t` can **offer its parent**: a path through the parent can continue into only **one** side of `t`, otherwise it would visit `t` and then turn back, which is not a path.
2. **bent(t):** `t.value + max(0, branch(left)) + max(0, branch(right))`. The best path whose highest node is `t`. It can use both sides, but it can **not** be extended upward.

The answer is the maximum `bent(t)` over all nodes.

`max(0, ...)`: a branch with a negative sum should be **dropped**, not forced into the path.

## Step 3: Algorithm

A post-order DFS that **returns** `branch(t)` to the parent and **records** `bent(t)` in a running best. This is Binary Tree Diameter with sums instead of heights.

```
branch(t):
    if t is null: return 0
    l = max(0, branch(t.left)); r = max(0, branch(t.right))
    best = max(best, t.value + l + r)
    return t.value + max(l, r)
```

## Step 4: The code

<!-- CODE:START -->

Full source: [`max_path_sum_in_binary_tree.dart`](max_path_sum_in_binary_tree.dart) (run it with `dart run`).

```dart
// Max Path Sum In Binary Tree: path between any two nodes (at least one node), values may be
// negative. Post-order returning the best downward "branch" sum; update a global best with the
// "bent" path through each node. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int maxPathSum(BinaryTree tree) {
  var best = tree.value;

  /// Max sum of a path starting at [t] and going down (possibly just t itself).
  int branch(BinaryTree? t) {
    if (t == null) return 0;
    final l = branch(t.left), r = branch(t.right);
    final leftGain = l > 0 ? l : 0, rightGain = r > 0 ? r : 0; // drop negative branches
    final throughT = t.value + leftGain + rightGain;
    if (throughT > best) best = throughT;
    return t.value + (leftGain > rightGain ? leftGain : rightGain);
  }

  branch(tree);
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `var best = tree.value;` starts from a real path sum (the root alone). Starting at 0 would be wrong for all-negative trees: `[-3]` must return -3.
- `branch` returns the best downward path starting at `t`.
- `leftGain` / `rightGain` clip negative branches to 0.
- `throughT` is the bent path; it updates `best`.
- The return value extends only the better side.

## Step 5: Dry run (second example)

| node | leftGain | rightGain | throughT | best | returns |
|---|---|---|---|---|---|
| 9 | 0 | 0 | 9 | 9 | 9 |
| 15 | 0 | 0 | 15 | 15 | 15 |
| 7 | 0 | 0 | 7 | 15 | 7 |
| 20 | 15 | 7 | **42** | 42 | 35 |
| -10 | 9 | 35 | 34 | 42 | 25 |

Answer: 42.

## Complexity

- **Time: O(n)**.
- **Space: O(h)**.

## Common mistakes

- Returning the bent path to the parent (it is not extendable).
- Initializing `best` to 0 (all-negative trees).
- Not clipping negative branches with `max(0, ...)`.

## Follow-ups

1. **Binary Tree Maximum Path Sum (LeetCode #124):** identical. Frequently asked at Google and Meta.
2. **Longest Univalue Path (#687):** same shape; branches extend only through equal values.
3. **Binary Tree Diameter (medium 22):** the same structure with lengths.

## What to remember

Separate "what I return to my parent" (a single downward branch) from "what I record as a candidate" (a path that may bend at me). Clip negative contributions.
