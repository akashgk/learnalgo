# Binary Tree Diameter

**Difficulty:** Medium | **Category:** Binary Trees | **Pattern:** Bottom-up DFS returning several values

## The problem

The **diameter** of a binary tree is the length of its longest path, measured in **edges**, between any two nodes. The path does not have to pass through the root. Return the diameter.

```
          1
        /   \
       3     2
     /   \
    7     4
   /       \
  8         5
 /           \
9             6

diameter = 6: 9 - 8 - 7 - 3 - 4 - 5 - 6   (it does not pass through the root)
```

## Step 1: Work an example by hand

Every path has a **highest node** where it bends: the path comes up from one side and goes down the other. For the path above, the bend is at 3. Its length is (the longest way down on the left of 3) + (the longest way down on the right of 3) = 3 + 3 = 6 edges.

So: `diameter = max over every node v of (height(v.left) + height(v.right))`, where height is measured in nodes (so a single node below counts as 1 edge from v).

## Step 2: Brute force

For every node, compute the heights of its two subtrees with separate traversals, then take the max. Heights cost O(size of subtree), and on a skewed tree the sizes sum to O(n^2).

**Duplicated work:** the height of a subtree is recomputed for every ancestor.

## Step 3: Optimize: compute everything bottom-up in one pass

A node's height depends only on its children's heights. So do a **post-order** traversal where each call returns **two numbers** about its subtree:

- `height`: longest downward path in nodes;
- `diameter`: best diameter found anywhere inside the subtree.

At node `t`, given the results `l` and `r` of its children:

```
throughT = l.height + r.height                 # best path bending at t
diameter = max(throughT, l.diameter, r.diameter)
height   = 1 + max(l.height, r.height)
```

Null nodes return `(diameter: 0, height: 0)`.

This "return a tuple of facts about my subtree" technique is one of the most important in tree interviews. Diameter, balance checks, max path sum, and largest BST subtree all use it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`binary_tree_diameter.dart`](binary_tree_diameter.dart) (run it with `dart run`).

```dart
// Binary Tree Diameter: longest path (in edges) between any two nodes.
// Post-order returning (diameter, height) as a record. O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int binaryTreeDiameter(BinaryTree tree) => _info(tree).diameter;

/// height = number of nodes on the longest downward path (0 for null).
({int diameter, int height}) _info(BinaryTree? t) {
  if (t == null) return (diameter: 0, height: 0);
  final l = _info(t.left), r = _info(t.right);
  final throughRoot = l.height + r.height; // edges of the longest path bending at t
  final best = [throughRoot, l.diameter, r.diameter].reduce((a, b) => a > b ? a : b);
  return (diameter: best, height: 1 + (l.height > r.height ? l.height : r.height));
}
```

<!-- CODE:END -->

### Walkthrough

- `({int diameter, int height})` is a Dart record with named fields: a clean way to return two values without defining a class.
- `final l = _info(t.left), r = _info(t.right);` recurses first (post-order).
- `throughRoot = l.height + r.height` counts **edges**: a height of k nodes below means k edges from `t` down to the deepest node.
- The returned height adds 1 for `t` itself.

## Step 5: Dry run (bottom-up)

| node | l (diam, h) | r (diam, h) | through | diameter | height |
|---|---|---|---|---|---|
| 9 | (0,0) | (0,0) | 0 | 0 | 1 |
| 8 | (0,1) | (0,0) | 1 | 1 | 2 |
| 7 | (1,2) | (0,0) | 2 | 2 | 3 |
| 6 | | | 0 | 0 | 1 |
| 5 | (0,0) | (0,1) | 1 | 1 | 2 |
| 4 | (0,0) | (1,2) | 2 | 2 | 3 |
| 3 | (2,3) | (2,3) | **6** | 6 | 4 |
| 2 | | | 0 | 0 | 1 |
| 1 | (6,4) | (0,1) | 5 | 6 | 5 |

Diameter: 6.

## Complexity

- **Time: O(n)**: each node is visited once with O(1) work.
- **Space: O(h)** for recursion.

## Common mistakes

- Returning `height(left) + height(right)` at the root only (misses paths that do not pass through the root, like this example).
- Mixing "edges" and "nodes": the answer here is edges; LeetCode #543 also uses edges.
- Using a global variable is fine (a common alternative), but mention it; returning a record keeps the function pure.

## Follow-ups

1. **Max Path Sum In Binary Tree (hard 13):** the same shape with sums instead of heights, and negative values.
2. **Height Balanced Binary Tree (medium 24):** return height plus a balanced flag.
3. **Diameter of an n-ary tree / general tree:** take the two largest child heights.
4. **Diameter of a general graph that is a tree:** BFS from any node to the farthest node u, then BFS from u; the farthest distance is the diameter.

## What to remember

When a node needs facts about its subtrees, return all of them at once from a post-order DFS. Track the global best separately from what you return to the parent.
