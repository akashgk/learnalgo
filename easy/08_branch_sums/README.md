# Branch Sums

**Difficulty:** Easy | **Category:** Binary Trees | **Pattern:** DFS with accumulated state (top-down)

## The problem

Given a binary tree, return a list of its **branch sums**, ordered from the leftmost branch to the rightmost. A branch sum is the sum of all values on a path from the root to a **leaf** (a node with no children).

```
          1
       /     \
      2       3
     / \     / \
    4   5   6   7
   / \  /
  8  9 10

branches: 1-2-4-8, 1-2-4-9, 1-2-5-10, 1-3-6, 1-3-7
sums:     15,      16,      18,       10,    11
```

### Clarifying questions

- What counts as the end of a branch? (Only a leaf. A node with one child, like 5 above, is not a branch end.)
- Can values be negative? (Yes in general; it does not change the algorithm.)
- What order? (Left to right.)

## Step 1: Work an example by hand

Follow the leftmost branch: start at 1, running total 1. Go to 2: total 3. Go to 4: total 7. Go to 8: total 15. Node 8 is a leaf, so record 15.

Back up to 4 and go right to 9: the total at 4 was 7, so at 9 it is 16. Record it.

Notice: when you return to node 4, you need the total **as it was at 4** (7), not the total you had at 8. If every node receives "the sum of everything above me" from its parent, you never have to undo anything. That is **top-down state**: passed from parent to child as a parameter.

## Step 2: The approach

Depth-first search, passing the running sum down:

```
dfs(node, runningSum):
    if node is null: return
    total = runningSum + node.value
    if node is a leaf: record total; return
    dfs(node.left, total)
    dfs(node.right, total)
```

Visiting left before right automatically produces the left-to-right order. That is a pre-order traversal.

There is no slower "brute force" worth discussing: every node must be visited once, so O(n) is optimal.

## Step 3: The code

<!-- CODE:START -->

Full source: [`branch_sums.dart`](branch_sums.dart) (run it with `dart run`).

```dart
// Branch Sums
// DFS carrying the running sum; record it at each leaf. Left-to-right order.
// O(n) time, O(n) space (output has at most ~n/2 leaves; recursion depth O(h)).

class BinaryTree {
  BinaryTree(this.value, [this.left, this.right]);
  int value;
  BinaryTree? left;
  BinaryTree? right;
}

List<int> branchSums(BinaryTree root) {
  final sums = <int>[];
  void dfs(BinaryTree? node, int running) {
    if (node == null) return;
    final total = running + node.value;
    if (node.left == null && node.right == null) {
      sums.add(total);
      return;
    }
    dfs(node.left, total);
    dfs(node.right, total);
  }

  dfs(root, 0);
  return sums;
}
```

<!-- CODE:END -->

### Walkthrough

- `final sums = <int>[];` collects the results. The nested function `dfs` can append to it directly (closure), so we do not need to pass it around.
- `if (node == null) return;` handles missing children. Without it, a node with only one child would crash on the other.
- `final total = running + node.value;` is the running sum including this node.
- `if (node.left == null && node.right == null)` is the leaf test. Record and stop.
- `dfs(node.left, total); dfs(node.right, total);` passes the **same** `total` to both children. Because `total` is a local value, the left subtree's work cannot corrupt what the right subtree receives. That is why no "undo" step is needed.

## Step 4: Dry run

| call | running (from parent) | total | leaf? | action |
|---|---|---|---|---|
| dfs(1, 0) | 0 | 1 | no | recurse |
| dfs(2, 1) | 1 | 3 | no | recurse |
| dfs(4, 3) | 3 | 7 | no | recurse |
| dfs(8, 7) | 7 | 15 | yes | record 15 |
| dfs(9, 7) | 7 | 16 | yes | record 16 |
| dfs(5, 3) | 3 | 8 | no | left child 10, right null |
| dfs(10, 8) | 8 | 18 | yes | record 18 |
| dfs(3, 1) | 1 | 4 | no | recurse |
| dfs(6, 4) | 4 | 10 | yes | record 10 |
| dfs(7, 4) | 4 | 11 | yes | record 11 |

Result: `[15, 16, 18, 10, 11]`.

## Complexity

- **Time: O(n)**: each node is visited once with O(1) work.
- **Space: O(n)** overall:
  - the output has one entry per leaf, and a binary tree can have up to about n/2 leaves;
  - the recursion stack is O(h): O(log n) when balanced, O(n) for a skewed tree.

## Edge cases

- A single node: one branch equal to its value.
- A skewed tree (every node has one child): exactly one branch, recursion depth n.
- A node with one child (like 5): not a leaf, so no sum is recorded there.

## Common mistakes

- Recording a sum when **either** child is null. Node 5 would wrongly produce the branch `1-2-5` with sum 8.
- Using a single mutable running-sum variable and forgetting to subtract when backtracking.

## Follow-ups

1. **Path Sum (LeetCode #112):** is there a branch with a given sum? Same DFS, return early.
2. **Path Sum II (#113):** return the actual paths. Keep a path list; append on the way down, remove on the way back (here backtracking **is** needed because the list is shared).
3. **Sum Root to Leaf Numbers (#129):** pass `running * 10 + value` instead of `running + value`.
4. **Iterative version:** a stack of `(node, runningSum)` pairs. Push the right child before the left so the left is processed first.

## What to remember

**Top-down** tree problems pass information from parent to child as parameters. **Bottom-up** problems return information from child to parent (see Binary Tree Diameter). Deciding which direction the information flows is the first step of every tree problem.
