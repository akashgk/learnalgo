# Validate Three Nodes

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** BST search between nodes

## The problem

Given three distinct nodes of a BST (`nodeOne`, `nodeTwo`, `nodeThree`), return whether `nodeTwo` lies strictly between the other two on a single downward path. That is, one of these holds:

- `nodeOne` is an ancestor of `nodeTwo`, and `nodeTwo` is an ancestor of `nodeThree`; or
- `nodeThree` is an ancestor of `nodeTwo`, and `nodeTwo` is an ancestor of `nodeOne`.

Nodes have no parent pointers.

```
          5
       /     \
      2       7
    /   \    / \
   1     4  6   8
  /     /
 0     3

(5, 2, 3) -> true    (5 is above 2, 2 is above 3)
(3, 2, 5) -> true    (the reversed order is also accepted)
(5, 7, 3) -> false   (7 is not above 3)
```

## Step 1: How do you test "X is an ancestor of Y" in a BST?

Search for Y's value starting from X, following the BST rule (go left if smaller, right otherwise). If the search reaches Y, then Y is in X's subtree. This takes O(h), no parent pointers needed.

Compare nodes by **identity**: the BST may contain duplicate values.

## Step 2: The logic

`nodeTwo` must be the middle node. Its ancestor must be one of the other two:

1. If `nodeOne` is an ancestor of `nodeTwo`: the answer is whether `nodeTwo` is an ancestor of `nodeThree`.
2. Else if `nodeThree` is an ancestor of `nodeTwo`: the answer is whether `nodeTwo` is an ancestor of `nodeOne`.
3. Otherwise false.

## Step 3: The code

<!-- CODE:START -->

Full source: [`validate_three_nodes.dart`](validate_three_nodes.dart) (run it with `dart run`).

```dart
// Validate Three Nodes: is nodeTwo a descendant of one of (nodeOne, nodeThree) and an ancestor
// of the other? Uses BST search downward from each node. O(h) time, O(1) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

bool validateThreeNodes(BST nodeOne, BST nodeTwo, BST nodeThree) {
  if (_isDescendant(nodeTwo, nodeOne)) return _isDescendant(nodeThree, nodeTwo);
  if (_isDescendant(nodeTwo, nodeThree)) return _isDescendant(nodeOne, nodeTwo);
  return false;
}

/// True if [target] is found by BST search starting from [node] (and target != node).
bool _isDescendant(BST node, BST target) {
  BST? current = node;
  while (current != null && !identical(current, target)) {
    current = target.value < current.value ? current.left : current.right;
  }
  return identical(current, target) && !identical(node, target);
}
```

<!-- CODE:END -->

### Walkthrough

- `_isDescendant(node, target)` walks down from `node` toward `target.value` and returns true if it reaches the target object itself (and the target is not the start node).
- `validateThreeNodes` applies the case analysis from Step 2.

## Step 4: Dry run: (5, 2, 3)

| check | walk | result |
|---|---|---|
| is 2 a descendant of 5? | 5 -> (2 < 5) -> 2 | yes |
| is 3 a descendant of 2? | 2 -> (3 > 2) -> 4 -> (3 < 4) -> 3 | yes |

Answer: true.

## Complexity

- **Time: O(h)**: at most three downward searches.
- **Space: O(1)**.

## Optimization (AlgoExpert's O(d) solution)

If the three nodes are close to each other but deep in a large tree, full searches are wasteful. Search from `nodeOne` and from `nodeThree` toward `nodeTwo` **simultaneously**, one step each per iteration, and stop as soon as either finds it or both fail. Work is bounded by `d`, the distance between the nodes, rather than the height. Mentioning this shows you considered the input distribution.

## Common mistakes

- Comparing values instead of node identity.
- Checking only one of the two orders.

## What to remember

In a BST, "is Y below X?" is just a search from X. Combine a few such searches with a clean case analysis.
