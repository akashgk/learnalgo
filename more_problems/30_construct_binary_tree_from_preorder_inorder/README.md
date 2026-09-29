# Construct Binary Tree from Preorder and Inorder Traversal

**Difficulty:** Medium | **Category:** Binary trees | **Pattern:** Divide and conquer with an index map | **Source:** LeetCode 105; Striver A2Z, NeetCode 150

## The problem

Given the preorder and inorder traversals of a binary tree with **unique** values, rebuild the tree.

```
preorder = [3, 9, 20, 15, 7]
inorder  = [9, 3, 15, 20, 7]

      3
     / \
    9   20
       /  \
      15   7
```

## Step 1: What each traversal tells us

- **Preorder** is `root, left subtree, right subtree`. So `preorder[0]` is the root.
- **Inorder** is `left subtree, root, right subtree`. So once we know the root, its position in inorder splits the rest into the left subtree's values (everything before it) and the right subtree's values (everything after it).

Example: root 3. In inorder, 3 is at index 1: the left subtree is `[9]` (1 node), the right subtree is `[15, 20, 7]` (3 nodes). In preorder, after the root come the left subtree's 1 node (`9`) and then the right subtree's 3 nodes (`20, 15, 7`). Recurse on each side.

Why are unique values required? With duplicates, the root's value could appear at several inorder positions and the split would be ambiguous.

## Step 2: Straightforward recursion

`build(preorder, inorder)`: take the root from preorder, find it in inorder with a linear search, slice both arrays, recurse. Slicing and searching cost O(n) per node: **O(n^2)** for a skewed tree.

## Step 3: Remove the two sources of waste

1. **Searching:** precompute `inIndex[value] = position in inorder`. O(1) lookups.
2. **Slicing:** do not copy arrays. Describe a subtree by its **inorder range** `[lo, hi]`, and read roots from preorder with **one global pointer** `pre` that only moves forward.

Why does a single forward pointer work? Preorder lists the root, then **all** of the left subtree, then all of the right subtree. If we build the left subtree completely before the right one, the recursion consumes preorder values in exactly the order they appear. Building the right subtree first would break this (that order is what you would use for postorder, from the end).

## Step 4: The code

<!-- CODE:START -->

Full source: [`construct_binary_tree_from_preorder_inorder.dart`](construct_binary_tree_from_preorder_inorder.dart) (run it with `dart run`).

```dart
// Construct Binary Tree from Preorder and Inorder Traversal (values are unique).
// The next preorder value is the root; its inorder position splits left and right subtrees.
// A value -> inorder index map makes each split O(1). O(n) time, O(n) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

TreeNode? buildTree(List<int> preorder, List<int> inorder) {
  final inIndex = {for (var i = 0; i < inorder.length; i++) inorder[i]: i};
  var pre = 0; // next unused preorder position
  // Builds the subtree whose inorder range is [lo, hi].
  TreeNode? build(int lo, int hi) {
    if (lo > hi) return null;
    final rootValue = preorder[pre++];
    final mid = inIndex[rootValue]!;
    final left = build(lo, mid - 1); // preorder lists the whole left subtree before the right
    final right = build(mid + 1, hi);
    return TreeNode(rootValue, left, right);
  }

  return build(0, inorder.length - 1);
}

List<int> preorderOf(TreeNode? t) => t == null ? [] : [t.value, ...preorderOf(t.left), ...preorderOf(t.right)];
List<int> inorderOf(TreeNode? t) => t == null ? [] : [...inorderOf(t.left), t.value, ...inorderOf(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- `inIndex` maps each value to its inorder position.
- `build(lo, hi)` returns null for an empty range.
- `preorder[pre++]` takes the next root. `mid = inIndex[rootValue]` splits the range.
- The left call **must** come before the right call (see Step 3).

## Step 5: Dry run

| call build(lo, hi) | pre before | root | mid | left range | right range |
|---|---|---|---|---|---|
| (0, 4) | 0 | 3 | 1 | (0, 0) | (2, 4) |
| (0, 0) | 1 | 9 | 0 | (0, -1) empty | (1, 0) empty |
| (2, 4) | 2 | 20 | 3 | (2, 2) | (4, 4) |
| (2, 2) | 3 | 15 | 2 | empty | empty |
| (4, 4) | 4 | 7 | 4 | empty | empty |

## Complexity

- Time: **O(n)**: each node is created once with O(1) work.
- Space: **O(n)** for the map, plus O(h) recursion (O(n) for a skewed tree).

## Edge cases

- Empty arrays: null.
- A single node.
- Skewed trees: inorder equals preorder (right-skewed) or its reverse (left-skewed).

## Common mistakes

- Building the right subtree before the left with a forward preorder pointer.
- Linear search for the root in inorder (O(n^2)).
- Off-by-one in the ranges (`mid - 1` and `mid + 1`).

## Follow-ups you should be ready for

1. **From inorder and postorder (LeetCode 106).** The root is the **last** postorder value; walk postorder backwards and build the **right** subtree first.
2. **From preorder and postorder (LeetCode 889).** Not unique in general (a node with one child could be left or right); the problem accepts any valid tree.
3. **From preorder alone for a BST.** Inorder is implied (sorted), or use value bounds; see AlgoExpert medium 20 Reconstruct BST.
4. **Serialize and deserialize.** Preorder with null markers is enough by itself; see more_problems 31.

## What to remember

Preorder gives the root; inorder splits around it. Use a value-to-index map and a single forward preorder pointer, building left before right, for O(n).
