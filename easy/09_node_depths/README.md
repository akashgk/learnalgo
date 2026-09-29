# Node Depths

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** DFS/BFS carrying depth

## The problem

The **depth** of a node is its distance (number of edges) from the root. Given a binary tree, return the sum of the depths of all its nodes.

```
          1            depth 0
       /     \
      2       3        depth 1, 1
     / \     / \
    4   5   6   7      depth 2, 2, 2, 2
   / \
  8   9                depth 3, 3

sum = 0 + 1 + 1 + 2*4 + 3*2 = 16
```

## Step 1: Work an example by hand

You did it level by level: the root contributes 0, each child of the root 1, each grandchild 2. The depth of a node is **its parent's depth plus one**. So depth is information that flows from the top down, just like the running sum in Branch Sums.

## Step 2: Recursive formulation

Define `f(node, d)` = the sum of depths in `node`'s subtree, given that `node` itself sits at depth `d`:

```
f(null, d) = 0
f(node, d) = d + f(node.left, d + 1) + f(node.right, d + 1)
```

The answer is `f(root, 0)`. This is a three-line function and a perfectly good interview answer.

## Step 3: Iterative formulation

Interviewers often ask for an iterative version too (deep trees can overflow the call stack). Store `(node, depth)` pairs on a stack:

- pop a pair, add its depth to the total;
- push each existing child with `depth + 1`.

The order of processing does not matter, because we only add numbers. A stack (DFS) or a queue (BFS) both work.

## Step 4: The code

<!-- CODE:START -->

Full source: [`node_depths.dart`](node_depths.dart) (run it with `dart run`).

```dart
// Node Depths
// Sum of every node's distance from the root. Iterative DFS with (node, depth) records.
// O(n) time, O(h) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

int nodeDepths(BinaryTree root) {
  var total = 0;
  final stack = <(BinaryTree, int)>[(root, 0)];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    total += depth;
    if (node.left case final l?) stack.add((l, depth + 1));
    if (node.right case final r?) stack.add((r, depth + 1));
  }
  return total;
}

/// Recursive one-liner version for comparison.
int nodeDepthsRecursive(BinaryTree? node, [int depth = 0]) =>
    node == null ? 0 : depth + nodeDepthsRecursive(node.left, depth + 1) + nodeDepthsRecursive(node.right, depth + 1);
```

<!-- CODE:END -->

### Walkthrough of the iterative `nodeDepths`

- `final stack = <(BinaryTree, int)>[(root, 0)];` is a stack of **records** (Dart's lightweight tuples). The root starts at depth 0.
- `final (node, depth) = stack.removeLast();` pops and destructures the record into two variables in one line.
- `total += depth;` counts this node.
- `if (node.left case final l?) stack.add((l, depth + 1));` is Dart's "if the value is not null, bind it to `l`" pattern. It pushes only real children.

### Walkthrough of `nodeDepthsRecursive`

It is the formula from Step 2 written as a single expression. `[int depth = 0]` is an optional positional parameter, so callers can write `nodeDepthsRecursive(root)`.

## Step 5: Dry run (iterative)

| pop | depth | total after | pushed |
|---|---|---|---|
| 1 | 0 | 0 | (2,1), (3,1) |
| 3 | 1 | 1 | (6,2), (7,2) |
| 7 | 2 | 3 | |
| 6 | 2 | 5 | |
| 2 | 1 | 6 | (4,2), (5,2) |
| 5 | 2 | 8 | |
| 4 | 2 | 10 | (8,3), (9,3) |
| 9 | 3 | 13 | |
| 8 | 3 | 16 | |

Result: 16.

## Complexity

- **Time: O(n)**: every node is pushed and popped once.
- **Space: O(h)** for DFS (h = height: O(log n) balanced, O(n) skewed). A BFS queue would use O(w) where w is the widest level, up to about n/2.

## Edge cases

- Single node: 0.
- Skewed tree of n nodes: `0 + 1 + ... + (n-1) = n(n-1)/2`.

## Common mistakes

- Counting depth in nodes instead of edges (root at depth 1). Read the definition.
- Forgetting to skip null children in the iterative version.

## Follow-ups

1. **All Kinds Of Node Depths (very hard 10):** sum the node depths for every subtree as if each node were the root. The naive approach repeats this problem n times; the clever one is O(n).
2. **Maximum depth (LeetCode #104), minimum depth (#111):** same traversal with max/min instead of sum. For minimum depth, BFS can stop at the first leaf.

## What to remember

Depth is top-down state: parent's depth + 1. Know both the recursive one-liner and the iterative stack-of-pairs version.
