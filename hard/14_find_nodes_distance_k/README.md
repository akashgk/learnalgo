# Find Nodes Distance K

**Difficulty:** Hard | **Category:** Binary Trees | **Pattern:** Turn the tree into an undirected graph, then BFS

## The problem

Given a binary tree with unique values, a `target` value that is in the tree, and a non-negative integer `k`, return the values of all nodes that are exactly `k` edges away from the target node, in any order.

```
          1
        /   \
       2     3
      / \     \
     4   5     6
              / \
             7   8

target = 3, k = 2  ->  [2, 7, 8]
```

From 3: going down two edges reaches 7 and 8; going up to 1 and then down reaches 2.

## Step 1: What makes it hard

Nodes **below** the target are easy: go down k levels. The difficulty is nodes reached by going **up** (to ancestors) and then down into **other** branches. Child pointers only go down.

## Step 2: Add the missing direction

With one traversal, record every node's **parent** in a hash map. Now each node has up to three neighbors: left child, right child, parent. The tree has become an **undirected graph**.

"All nodes at distance exactly k" in an unweighted graph is **BFS for k levels** from the target. Keep a visited set so you never walk back along the edge you came from.

## Step 3: The code

<!-- CODE:START -->

Full source: [`find_nodes_distance_k.dart`](find_nodes_distance_k.dart) (run it with `dart run`).

```dart
// Find Nodes Distance K: values of nodes exactly k edges from the node with value `target`.
// Build parent pointers, then BFS outward treating the tree as an undirected graph.
// O(n) time, O(n) space.

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

List<int> findNodesDistanceK(BinaryTree tree, int target, int k) {
  final parent = <BinaryTree, BinaryTree?>{tree: null};
  BinaryTree? start;
  final stack = [tree];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    if (node.value == target) start = node;
    for (final child in [node.left, node.right].nonNulls) {
      parent[child] = node;
      stack.add(child);
    }
  }
  if (start == null) return [];

  final seen = <BinaryTree>{start};
  var frontier = [start];
  for (var d = 0; d < k && frontier.isNotEmpty; d++) {
    final next = <BinaryTree>[];
    for (final node in frontier) {
      for (final nb in [node.left, node.right, parent[node]].nonNulls) {
        if (seen.add(nb)) next.add(nb);
      }
    }
    frontier = next;
  }
  return [for (final n in frontier) n.value];
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop (iterative DFS) fills `parent` and finds the `start` node with the target value.
- `seen` prevents revisiting nodes.
- `frontier` is the current BFS level. Each iteration builds the next level from the neighbors `[left, right, parent]` (with `.nonNulls` dropping missing ones).
- After k iterations, the frontier is exactly the set of nodes at distance k.

## Step 4: Dry run (target 3, k = 2)

| level | frontier |
|---|---|
| 0 | 3 |
| 1 | 6 (child), 1 (parent) |
| 2 | from 6: 7, 8; from 1: 2 (3 already seen) |

Answer: `[7, 8, 2]` (any order).

## Complexity

- **Time: O(n)**: building the parent map plus BFS.
- **Space: O(n)** for the map, the visited set, and the frontier.

## Alternative without extra maps

A recursive function that returns the distance from each subtree to the target:

- when the target is found, collect nodes k levels below it;
- on the way back up, an ancestor at distance `d` from the target contributes itself if `d == k`, and collects nodes `k - d - 1` levels down its **other** subtree.

O(n) time, O(h) space. Elegant, but much easier to get wrong under pressure; the parent-map BFS is the safer interview answer.

## Common mistakes

- Only searching below the target.
- Forgetting the visited set (BFS bounces between a node and its parent).

## Follow-ups

1. **All Nodes Distance K in Binary Tree (LeetCode #863):** identical.
2. **Closest leaf to a target (#742):** BFS on the same graph until the first leaf.
3. **Amount of Time for Binary Tree to Be Infected (#2385):** BFS levels from the start node until the whole tree is covered.

## What to remember

When a tree problem needs to move upward, add parent pointers (a hash map) and treat the tree as an undirected graph.
