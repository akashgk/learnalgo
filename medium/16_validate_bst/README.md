# Validate BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Top-down bounds

## The problem

Given a binary tree, return whether it is a valid BST: every node's value is strictly greater than every value in its left subtree, and less than or equal to every value in its right subtree.

```
valid:                    invalid:
      10                        10
     /  \                      /  \
    5    15                   5    15
   / \                         \
  2   5                         11     <- 11 is in the LEFT subtree of 10
```

## Step 1: The trap

The tempting solution checks each node only against its **direct** children: `left.value < node.value <= right.value`. In the invalid tree above, every parent-child pair passes that check: 5 < 10, 15 >= 10, 11 >= 5. Yet 11 sits in the left subtree of 10, so it must be less than 10. The local check misses violations against **grandparents and higher ancestors**. Interviewers use exactly this example to see whether you fall for it.

## Step 2: The right idea: every node has a valid range

Each node must fall inside a range determined by **all** of its ancestors:

- the root can be anything: `(-infinity, +infinity)`;
- going **left** from a node with value `v` means "everything here must be `< v`": the upper bound becomes `v`;
- going **right** means "everything here must be `>= v`": the lower bound becomes `v`.

Pass the range down (top-down state), tightening one side at each step:

```
validate(node, min, max):
    if node is null: return true
    if node.value < min or node.value >= max: return false
    return validate(node.left, min, node.value) and validate(node.right, node.value, max)
```

In the invalid tree, node 11 receives the range `[5, 10)` (greater than or equal to 5 from its parent, less than 10 from the root) and fails.

## Step 3: The code

<!-- CODE:START -->

Full source: [`validate_bst.dart`](validate_bst.dart) (run it with `dart run`).

```dart
// Validate BST: every node must be within (min, max) bounds inherited from ancestors.
// Left subtree: strictly less. Right subtree: greater or equal.
// O(n) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

bool validateBst(BST? tree, [int? min, int? max]) {
  if (tree == null) return true;
  if (min != null && tree.value < min) return false; // must be >= min
  if (max != null && tree.value >= max) return false; // must be < max
  return validateBst(tree.left, min, tree.value) && validateBst(tree.right, tree.value, max);
}
```

<!-- CODE:END -->

### Walkthrough

- `[int? min, int? max]` are optional nullable bounds; `null` means "unbounded". Using `null` instead of the smallest/largest integer avoids bugs when the tree actually contains those extreme values.
- `if (min != null && tree.value < min) return false;` enforces the lower bound (values equal to `min` are allowed, since duplicates go right).
- `if (max != null && tree.value >= max) return false;` enforces the strict upper bound.
- The recursive calls tighten the range: left gets `max = tree.value`, right gets `min = tree.value`.
- `&&` short-circuits: if the left subtree is invalid, the right is not explored.

## Step 4: Dry run on the invalid tree

| node | range [min, max) | ok? |
|---|---|---|
| 10 | (-inf, +inf) | yes |
| 5 | (-inf, 10) | yes |
| 11 | [5, 10) | **no**: 11 >= 10 |

Returns false without visiting 15.

## Complexity

- **Time: O(n)**: each node is checked once.
- **Space: O(h)** for recursion (O(log n) balanced, O(n) skewed).

## Alternative: in-order traversal

An in-order traversal of a BST produces values in sorted order. So traverse in-order and check that each value is not smaller than the previous one. Also O(n) time and O(h) space.

Caveat with this problem's duplicate rule: in-order cannot tell whether an equal value came from the left or the right subtree. `10` with a **left** child `10` is invalid here, but in-order gives `10, 10`, which looks fine. The bounds approach handles it (the left child gets `max = 10` and `10 >= 10` fails). This is a good reason to prefer the bounds version here.

## Common mistakes

- Comparing only with direct children.
- Using `int` min/max sentinels that collide with real values.
- Getting the equality rule backwards (`<=` vs `<`) for this problem's duplicate convention.

## Follow-ups

1. **LeetCode #98:** no duplicates allowed at all, so both bounds are strict.
2. **Find the two swapped nodes and fix the tree:** Repair BST (hard 11).
3. **Largest subtree that is a valid BST:** bottom-up version (see Sum BSTs, hard 12).

## What to remember

Tree constraints that involve **ancestors** (not just parents) are enforced by passing bounds down the recursion.
