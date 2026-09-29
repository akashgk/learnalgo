# Min Height BST

**Difficulty:** Medium | **Category:** Binary Search Trees | **Pattern:** Divide and conquer

## The problem

Given a **sorted** array of distinct integers, build a BST containing all of them with the **minimum possible height**, and return its root.

```
[1, 2, 5, 7, 10, 13, 14, 15, 22]  ->

             10
          /      \
         2        14
        / \      /  \
       1   5    13   15
            \          \
             7          22
```

(Several trees have the minimum height; any of them is accepted.)

## Step 1: What goes wrong naively

Inserting the values in the given sorted order: 1 becomes the root, 2 goes right of 1, 5 right of 2, and so on. The result is a chain of height 9, the worst possible BST.

For minimum height, every node should split the remaining values into two halves of (almost) equal size.

## Step 2: The idea

The root should be the value that splits the array into two equal halves: the **middle** element. Everything to its left is smaller (the left subtree), everything to its right is bigger (the right subtree). Then apply the same rule to each half, recursively.

This is binary search, but instead of discarding a half, you build a subtree from each half.

```
build(lo, hi):
    if lo > hi: return null
    mid = (lo + hi) / 2
    node = new node(array[mid])
    node.left  = build(lo, mid - 1)
    node.right = build(mid + 1, hi)
    return node
```

The BST property holds automatically because the array is sorted.

## Step 3: The code

<!-- CODE:START -->

Full source: [`min_height_bst.dart`](min_height_bst.dart) (run it with `dart run`).

```dart
// Min Height BST from a sorted array of distinct integers.
// Recursively take the middle element as root. O(n) time, O(n) space.

class BST {
  BST(this.value);
  int value;
  BST? left;
  BST? right;
}

BST? minHeightBst(List<int> array) => _build(array, 0, array.length - 1);

BST? _build(List<int> a, int lo, int hi) {
  if (lo > hi) return null;
  final mid = (lo + hi) ~/ 2;
  return BST(a[mid])
    ..left = _build(a, lo, mid - 1)
    ..right = _build(a, mid + 1, hi);
}

int height(BST? t) => t == null ? 0 : 1 + [height(t.left), height(t.right)].reduce((a, b) => a > b ? a : b);
List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- `minHeightBst(array)` calls the helper on the full index range.
- `_build(a, lo, hi)` works on index ranges instead of creating subarrays, avoiding O(n log n) copying.
- `if (lo > hi) return null;` is the empty range.
- Dart's cascade (`..left = ...`, `..right = ...`) builds the node and attaches both subtrees in one expression.
- `height` and `inOrder` are test helpers.

## Step 4: Dry run

Array indices 0..8: `[1, 2, 5, 7, 10, 13, 14, 15, 22]`:

| range | mid | node | left range | right range |
|---|---|---|---|---|
| 0..8 | 4 | 10 | 0..3 | 5..8 |
| 0..3 | 1 | 2 | 0..0 | 2..3 |
| 0..0 | 0 | 1 | empty | empty |
| 2..3 | 2 | 5 | empty | 3..3 (7) |
| 5..8 | 6 | 14 | 5..5 (13) | 7..8 |
| 7..8 | 7 | 15 | empty | 8..8 (22) |

Height = 4 levels, which is `ceil(log2(9 + 1)) = 4`, the minimum for 9 nodes.

## Complexity

- **Time: O(n)**: each element becomes exactly one node, created in O(1).
- **Space: O(n)** for the tree; O(log n) recursion depth.

A common slower variant builds the tree by calling `insert` for the middle element of each range: each insert walks from the root, O(log n), so O(n log n) total. Building nodes directly avoids that.

## Common mistakes

- Creating subarray copies at each level (O(n log n) time and memory).
- Off-by-one in the ranges (`mid` included in a child range, causing infinite recursion or duplicated nodes).

## Follow-ups

1. **LeetCode #108 (Convert Sorted Array to BST):** identical.
2. **#109 (Sorted Linked List to BST):** no random access to find the middle. Either find the middle with fast/slow pointers each time (O(n log n)), or simulate an in-order traversal: build the left subtree recursively, consume the next list node as the root, then build the right subtree (O(n)).
3. **Balance an existing BST (#1382):** in-order traversal into an array, then this algorithm.

## What to remember

Minimum height means every node splits its range in half: take the middle as the root and recurse on both halves.
