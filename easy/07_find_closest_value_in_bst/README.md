# Find Closest Value In BST

**Difficulty:** Easy | **Category:** Binary Search Trees | **Pattern:** BST descent

## The problem

Given the root of a Binary Search Tree (BST) and a target integer, return the value in the BST closest to the target. Assume there is exactly one closest value.

**BST property:** each node's value is strictly greater than every value in its left subtree, and less than or equal to every value in its right subtree.

```
          10
        /    \
       5      15
      / \    /  \
     2   5  13   22
    /         \
   1           14

target = 12  ->  13
```

### Clarifying questions

- Is the tree balanced? (Not guaranteed. This changes the worst-case complexity.)
- What if two values are equally close? (Guaranteed not to happen here; otherwise ask which one to return.)
- Can the tree be empty? (No, at least one node.)

## Step 1: Work an example by hand

Target 12, start at the root.

- At 10: difference 2. The target is bigger than 10. Everything in the **left** subtree of 10 is smaller than 10, so it is even farther from 12 than 10 is. Ignore the left subtree; go right.
- At 15: difference 3. Worse than 10, but keep going. 12 < 15, so everything in the right subtree (>= 15) is even farther. Go left.
- At 13: difference 1. Best so far. 12 < 13, go left.
- Left child of 13 is empty. Stop. Answer: 13.

At every node we threw away an entire subtree. That is binary search on a tree.

## Step 2: Brute force

Visit every node (any traversal), keep the value with the smallest `|target - value|`. O(n) time. This works on **any** binary tree, which is the hint that it is not using the BST property.

## Step 3: Optimize using the BST property

At a node with value `v`:

- If `target < v`: every value in the right subtree is `>= v > target`, so each is at least as far from the target as `v`. The right subtree cannot contain a better answer. Go left.
- If `target > v`: symmetric, go right.
- If `target == v`: the distance is 0, which cannot be beaten. Stop.

While walking, keep the best value seen so far. The closest value must lie on this single root-to-leaf path, because every subtree we skipped was proven worse than a node on the path.

### Recursive or iterative?

Both are natural. The recursive version uses O(h) call-stack space. The iterative version uses O(1). Since the recursion is a **tail call** (we only go down one branch and never combine results), converting it to a loop is trivial, so prefer the loop.

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_closest_value_in_bst.dart`](find_closest_value_in_bst.dart) (run it with `dart run`).

```dart
// Find Closest Value In BST
// Walk down from the root, keeping the best candidate; the BST property tells us which
// subtree could hold something closer. Average O(log n), worst O(n) time; O(1) space iteratively.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

int findClosestValueInBst(BST tree, int target) {
  var closest = tree.value;
  BST? node = tree;
  while (node != null) {
    if ((target - node.value).abs() < (target - closest).abs()) closest = node.value;
    if (target < node.value) {
      node = node.left;
    } else if (target > node.value) {
      node = node.right;
    } else {
      break; // exact match
    }
  }
  return closest;
}
```

<!-- CODE:END -->

### Walkthrough

- `var closest = tree.value;` starts with the root as the best candidate, which is valid because the tree is non-empty.
- `BST? node = tree;` is the current position; it becomes `null` when we fall off the tree.
- `if ((target - node.value).abs() < (target - closest).abs()) closest = node.value;` updates the best candidate.
- The three branches implement Step 3. The `break` on equality is an early exit.

## Step 5: Dry run

Target 12:

| node | distance | closest after | move |
|---|---|---|---|
| 10 | 2 | 10 | 12 > 10, go right |
| 15 | 3 | 10 | 12 < 15, go left |
| 13 | 1 | 13 | 12 < 13, go left |
| null | | 13 | stop |

## Complexity

| Tree shape | Time | Space (iterative) | Space (recursive) |
|---|---|---|---|
| Balanced | O(log n) | O(1) | O(log n) |
| Skewed (a linked list) | O(n) | O(1) | O(n) |

Always state both. A plain BST is not self-balancing: inserting sorted data creates a chain of height n.

## Edge cases

- Target smaller than every value: walk left to the minimum.
- Target larger than every value: walk right to the maximum.
- Single node: that node.
- Duplicates (the two 5s): harmless; either one has the same distance.

## Common mistakes

- Returning the last visited node instead of the best one seen. With target 11 the walk is 10 (distance 1), 15 (distance 4), 13 (distance 2), then falls off the tree. The last node is 13, but the answer is 10.
- Exploring both subtrees "just in case", which silently turns it back into O(n).

## Follow-ups

1. **k closest values (LeetCode #272).** In-order traversal gives sorted values; keep a sliding window of size k, or use two stacks (predecessors and successors) for O(h + k).
2. **Closest value in a sorted array.** Same idea with binary search.
3. **Floor and ceiling in a BST** (largest value <= target, smallest value >= target): same walk, update the candidate only on one side.

## What to remember

In a BST, compare with the current node and discard the half that cannot contain the answer. Track the best candidate along the single path you walk.
