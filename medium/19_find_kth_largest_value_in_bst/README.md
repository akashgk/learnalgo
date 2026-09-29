# Find Kth Largest Value In BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Reverse in-order traversal with early exit

## The problem

Given a BST and a positive integer k (at most the number of nodes), return the k-th largest value. Duplicates count as separate values.

```
            15
          /    \
         5      20
        / \    /  \
       2   5  17   22
      / \
     1   3

k = 3  ->  17     (22, 20, 17, ...)
```

## Step 1: Work an example by hand

The largest value in a BST is the rightmost node (22). The second largest is 20, then 17. You are reading the tree **from right to left**, which is a descending order.

## Step 2: Simple solution

In-order traversal gives values in ascending order. Collect them all, return `values[n - k]`. **O(n)** time and **O(n)** space. A good baseline, but it visits the whole tree even when k = 1.

## Step 3: Optimize: reverse in-order, stop after k

**Reverse in-order** (right subtree, node, left subtree) visits values in **descending** order. Count visits and stop at the k-th one. You only touch the nodes on the path down to the maximum plus about k more.

An iterative traversal with an explicit stack makes stopping trivial (no need to propagate a "done" flag up through recursive calls).

```
node = root
while node != null or stack not empty:
    while node != null: push node; node = node.right   # go to the largest
    node = pop()
    visited += 1; if visited == k: return node.value
    node = node.left                                    # then smaller values
```

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_kth_largest_value_in_bst.dart`](find_kth_largest_value_in_bst.dart) (run it with `dart run`).

```dart
// Find Kth Largest Value In BST. Reverse in-order (right, node, left) visits values in
// descending order; stop after k visits. O(h + k) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

int findKthLargestValueInBst(BST tree, int k) {
  final stack = <BST>[];
  BST? node = tree;
  var visited = 0;
  while (node != null || stack.isNotEmpty) {
    while (node != null) {
      stack.add(node);
      node = node.right; // go as far right (largest) as possible
    }
    final current = stack.removeLast();
    if (++visited == k) return current.value;
    node = current.left;
  }
  throw ArgumentError('k is larger than the tree size');
}
```

<!-- CODE:END -->

### Walkthrough

- The inner `while` pushes the path to the largest remaining value.
- `stack.removeLast()` gives the next value in descending order.
- `if (++visited == k) return current.value;` counts and stops early.
- `node = current.left;` continues with the values just below `current`.
- The final `throw` only happens if k exceeds the number of nodes.

## Step 5: Dry run (k = 3)

| step | stack (bottom -> top) | popped | visited |
|---|---|---|---|
| push 15, 20, 22 | 15, 20, 22 | | |
| pop | 15, 20 | 22 | 1 |
| 22 has no left; pop | 15 | 20 | 2 |
| go to 20's left: push 17; pop | 15 | 17 | **3 -> return 17** |

## Complexity

- **Time: O(h + k)**: h to reach the maximum, then k visits (each pop may push a short path, but across the whole traversal every node is pushed at most once).
- **Space: O(h)** for the stack.

## Common mistakes

- Doing a normal in-order traversal and returning the k-th element (that is the k-th **smallest**).
- Traversing the whole tree even after finding the answer.

## Follow-ups

1. **k-th smallest (LeetCode #230):** normal in-order with the same early exit.
2. **Frequent inserts/deletes and many k-th queries:** augment each node with its subtree size. Then k-th largest is O(h): compare k with `size(right) + 1` to decide where to go. Updates maintain sizes along the path.
3. **k-th largest in an unsorted array:** a min-heap of size k or Quickselect (hard 46).

## What to remember

In-order = ascending, reverse in-order = descending. An iterative stack traversal lets you stop as soon as you have what you need.
