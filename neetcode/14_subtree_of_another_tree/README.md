# Subtree of Another Tree

**Difficulty:** Easy | **Category:** Trees | **Pattern:** Same Tree at every node (or serialize + string search) | **Source:** LeetCode 572; NeetCode 150, Blind 75

## The problem

Return true if `root` contains a node whose **entire** subtree is identical to `subRoot` (same structure and values, all the way down to the leaves).

```
     3              4
    / \            / \
   4   5          1   2        ->  true
  / \
 1   2
```

If the `2` in `root` had a child, the answer would be false: a subtree must match **completely**, not just its top part.

## Step 1: Reduce to Same Tree

"Is `subRoot` equal to the subtree at node X?" is exactly Same Tree (neetcode 13). So:

```
isSubtree(root, sub) = sameTree(root, sub) || isSubtree(root.left, sub) || isSubtree(root.right, sub)
```

Try every node of `root` as the candidate top.

## Step 2: Cost

For each of the n nodes of `root`, Same Tree may run up to m steps (m = size of `subRoot`): **O(n * m)** worst case. In practice, a mismatch at the top of the candidate stops early, so it is usually much faster.

## Step 3: O(n + m) with serialization

Serialize both trees with preorder **and null markers** (as in more_problems 31), with a separator before each value so that `2` does not match inside `12`: for example `",3,4,1,#,#,2,#,#,5,#,#"`. Then `subRoot` is a subtree of `root` exactly when its serialization is a **substring** of `root`'s. Use KMP (AlgoExpert very_hard 17) for guaranteed O(n + m).

Why the null markers and separators? Without nulls, different shapes can serialize identically; without separators, values can merge (`1,2` vs `12`).

## Step 4: The code

<!-- CODE:START -->

Full source: [`subtree_of_another_tree.dart`](subtree_of_another_tree.dart) (run it with `dart run`).

```dart
// Subtree of Another Tree: does root contain a node whose entire subtree equals subRoot?
// For every node of root, run Same Tree against subRoot. O(n * m) time worst case, O(h) space.
// (An O(n + m) alternative serializes both trees and runs string matching; see the README.)

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

bool isSubtree(TreeNode? root, TreeNode? subRoot) {
  if (subRoot == null) return true; // the empty tree is a subtree of everything
  if (root == null) return false;
  return _same(root, subRoot) || isSubtree(root.left, subRoot) || isSubtree(root.right, subRoot);
}

bool _same(TreeNode? p, TreeNode? q) {
  if (p == null || q == null) return p == q;
  return p.value == q.value && _same(p.left, q.left) && _same(p.right, q.right);
}
```

<!-- CODE:END -->

### Walkthrough

- An empty `subRoot` is a subtree of anything (by convention; LeetCode's inputs are non-empty).
- `_same` is Same Tree.
- `||` short-circuits: the search stops at the first match.

## Step 5: Dry run

Example above:

| candidate in root | same as sub? |
|---|---|
| 3 | no (3 != 4) |
| 4 | compare 4 = 4, 1 = 1, 2 = 2, all children null: **yes** |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Same Tree at every node | O(n * m) worst | O(h) |
| Serialize + KMP | O(n + m) | O(n + m) |

## Edge cases

- `root` has one node equal to `subRoot`'s value but `subRoot` has children: false.
- The match is a leaf deep in the tree.
- `root` empty and `subRoot` non-empty: false.

## Common mistakes

- Checking only whether the values of `subRoot` appear in `root` in the right order (a partial match is not a subtree).
- Serializing without null markers or separators.

## Follow-ups you should be ready for

1. **Hashing (Merkle-style).** Hash each subtree from its children's hashes; compare hashes, then confirm with Same Tree on collision. O(n + m) expected.
2. **Count occurrences of subRoot.** Same approach, count instead of returning early.
3. **Find duplicate subtrees (LeetCode 652).** Serialize every subtree into a map of counts.

## What to remember

"Subtree" = Same Tree at some node. For guaranteed linear time, serialize with null markers and use string matching.
