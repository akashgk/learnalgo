# Reconstruct BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Consume pre-order with bounds

## The problem

You are given the **pre-order traversal** of a BST (node, left subtree, right subtree), where duplicates go to the right subtree. Rebuild the BST and return its root.

```
preOrder = [10, 4, 2, 1, 5, 17, 19, 18]

            10
          /    \
         4      17
        / \       \
       2   5       19
      /           /
     1           18
```

## Step 1: Work an example by hand

Pre-order starts with the root: 10. Then comes the **entire** left subtree, then the entire right subtree. Everything smaller than 10 belongs to the left subtree: `[4, 2, 1, 5]`. The rest `[17, 19, 18]` is the right subtree. Apply the same rule to each part: in `[4, 2, 1, 5]`, root 4, left `[2, 1]`, right `[5]`. And so on.

## Step 2: Straightforward recursion: O(n^2)

```
build(values):
    root = values[0]
    split = first index whose value >= root
    root.left  = build(values[1..split))
    root.right = build(values[split..])
```

Finding the split point is a linear scan. For a skewed tree (for example sorted input `[1, 2, 3, 4, ...]`) every level scans almost everything: **O(n^2)** time. Balanced trees give O(n log n).

## Step 3: Optimize: read each value exactly once

Walk through the pre-order array with **one shared index**. Each recursive call builds a subtree that only accepts values within a range `[lower, upper)`, exactly like Validate BST:

```
build(lower, upper):
    if no values left, or next value is outside [lower, upper): return null   # this subtree is empty
    value = next value; advance the index
    node.left  = build(lower, value)      # smaller values go left
    node.right = build(value, upper)      # values >= node go right
    return node
```

**Why this works:** pre-order emits a node, then its whole left subtree, then its whole right subtree. When the left-subtree call sees a value that is too big for it (outside its range), that value must belong to some right subtree higher up. The call returns without consuming it, and the right place picks it up.

Every value is consumed exactly once, so the whole reconstruction is **O(n)**.

## Step 4: The code

<!-- CODE:START -->

Full source: [`reconstruct_bst.dart`](reconstruct_bst.dart) (run it with `dart run`).

```dart
// Reconstruct BST from its pre-order traversal (duplicates go right).
// Consume values left to right; each recursive call accepts values in [lower, upper).
// O(n) time, O(n) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

BST? reconstructBst(List<int> preOrder) {
  var index = 0;
  BST? build(int? lower, int? upper) {
    if (index == preOrder.length) return null;
    final value = preOrder[index];
    if ((lower != null && value < lower) || (upper != null && value >= upper)) return null;
    index++;
    final node = BST(value);
    node.left = build(lower, value);
    node.right = build(value, upper);
    return node;
  }

  return build(null, null);
}

List<int> preOrder(BST? t) => t == null ? [] : [t.value, ...preOrder(t.left), ...preOrder(t.right)];
List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- `var index = 0;` is shared by all recursive calls through the closure `build`.
- `build(int? lower, int? upper)`: `null` means unbounded.
- `if (index == preOrder.length) return null;` means no values left.
- The range check returns `null` **without** advancing `index`: the value is left for an ancestor's right subtree.
- `node.left = build(lower, value); node.right = build(value, upper);` follows the duplicate rule (equal values fall into the right range `[value, upper)`).

## Step 5: Dry run

`[10, 4, 2, 1, 5, 17, 19, 18]`:

| call range | next value | action |
|---|---|---|
| (-inf, inf) | 10 | create 10 |
| (-inf, 10) | 4 | create 4 (left of 10) |
| (-inf, 4) | 2 | create 2 |
| (-inf, 2) | 1 | create 1 |
| (-inf, 1) | 5 | out of range: null (1 has no left) |
| [1, 2) | 5 | out of range: null (1 has no right) |
| [2, 4) | 5 | out of range: null (2 has no right) |
| [4, 10) | 5 | create 5 (right of 4) |
| ... 5's children | 17 | out of range: null, null |
| [10, inf) | 17 | create 17 (right of 10) |
| [10, 17) | 19 | null (17 has no left) |
| [17, inf) | 19 | create 19 |
| [17, 19) | 18 | create 18 (left of 19) |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Split at first bigger value | O(n^2) worst, O(n log n) balanced | O(n) |
| Shared index + bounds | **O(n)** | O(n) for the tree, O(h) recursion |

## Common mistakes

- Advancing the index before checking the range (consumes a value that belongs elsewhere).
- Using `>` vs `>=` inconsistently with the duplicate rule.

## Follow-ups

1. **LeetCode #1008:** identical. A monotonic stack gives another O(n) solution: for each value, pop while the stack top is smaller; the last popped node gets it as a right child, otherwise it becomes the left child of the top.
2. **From post-order:** read the array from the end (node, right, left).
3. **General binary tree (not a BST):** one traversal is not enough; you need pre-order + in-order (#105) or post-order + in-order (#106).

## What to remember

A BST is fully determined by its pre-order. Consume values in order and let each subtree accept only values within its bounds.
