# Binary Tree Right Side View

**Difficulty:** Medium | **Category:** Trees | **Pattern:** DFS right-first recording the first node per depth (or BFS last per level) | **Source:** LeetCode 199; NeetCode 150

## The problem

Imagine standing to the right of the tree. Return the values you can see, top to bottom: the **rightmost node of every level**.

```
    1
   / \
  2   3        ->  [1, 3, 4]
   \   \
    5   4
```

## Step 1: The trap

"Follow right children from the root" is wrong. If the left subtree is deeper, its bottom levels are visible from the right:

```
    1
   / \
  2   3        ->  [1, 3, 4]   (4 is in the LEFT subtree, but nothing is to its right)
 /
4
```

## Step 2: BFS version

Level order traversal (neetcode 16), keeping the **last** node of each level. Straightforward.

## Step 3: DFS version

Visit the right child **before** the left child, carrying the depth. The **first** node reached at each depth is the rightmost node of that level, because everything to its right has already been explored (and did not reach that depth). Record a value when `depth == view.length` (a depth seen for the first time).

## Step 4: The code

<!-- CODE:START -->

Full source: [`binary_tree_right_side_view.dart`](binary_tree_right_side_view.dart) (run it with `dart run`).

```dart
// Binary Tree Right Side View: the value you would see at each level looking from the right,
// i.e. the last node of every level. DFS visiting right before left, recording the first node
// seen at each depth. O(n) time, O(h) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<int> rightSideView(TreeNode? root) {
  final view = <int>[];
  void dfs(TreeNode? node, int depth) {
    if (node == null) return;
    // The first node reached at a new depth is the rightmost one, because right is explored first.
    if (depth == view.length) view.add(node.value);
    dfs(node.right, depth + 1);
    dfs(node.left, depth + 1);
  }

  dfs(root, 0);
  return view;
}
```

<!-- CODE:END -->

### Walkthrough

- `view.length` is the number of depths already recorded, so `depth == view.length` means "new depth".
- Right before left is essential; swapping them gives the **left** side view.

## Step 5: Dry run

Second tree above:

| visit | depth | view before | recorded? | view after |
|---|---|---|---|---|
| 1 | 0 | [] | yes | [1] |
| 3 | 1 | [1] | yes | [1, 3] |
| 2 | 1 | [1, 3] | no | [1, 3] |
| 4 | 2 | [1, 3] | yes | [1, 3, 4] |

## Complexity

- Time: **O(n)**.
- Space: **O(h)** for DFS, O(w) for BFS.

## Edge cases

- Empty tree: `[]`.
- Only left children: every node is visible.

## Common mistakes

- Following only right pointers.
- Visiting left first and recording the first node per depth (that is the left view).

## Follow-ups you should be ready for

1. **Left side view.** Visit left first.
2. **Top / bottom view.** Group by column instead of depth; see more_problems 29 Vertical Order Traversal.
3. **Rightmost value at the deepest level.** The last element of this view.

## What to remember

Rightmost per level: DFS right-first and keep the first node at each new depth, or BFS and keep the last node of each level.
