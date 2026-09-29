# Vertical Order Traversal of a Binary Tree

**Difficulty:** Hard | **Category:** Binary trees | **Pattern:** Coordinate labeling + sort | **Source:** LeetCode 987; Striver A2Z

## The problem

Place the root at (row 0, column 0). A node at (row, col) has its left child at (row + 1, col - 1) and its right child at (row + 1, col + 1). Return the node values column by column, from the leftmost column to the rightmost. Within a column, order by row (top to bottom); **nodes in the same row and column are ordered by value**.

```
      3
     / \
    9   20          ->  [[9], [3, 15], [20], [7]]
       /  \
      15   7
```

```
        1
      /   \
     2     3
    / \   / \       ->  [[4], [2], [1, 5, 6], [3], [7]]
   4   5 6   7
```

In the second tree, 5 (the left child's right child) and 6 (the right child's left child) are both at (row 2, column 0). They tie, so they are sorted by value.

### Clarifying questions to ask

This problem has several versions, and interviewers often do not say which one they mean:

| Version | Tie rule inside a (row, col) cell |
|---|---|
| LeetCode 987 (this one) | sort by value |
| LeetCode 314 (premium) | left to right, i.e. BFS order |
| Top view / bottom view (Striver) | only the first / last node of each column |

Ask. The coordinate labeling is the same for all; only the ordering changes.

## Step 1: Label every node

A single DFS (or BFS) assigns each node its `(col, row)`. That is the whole traversal part: O(n).

## Step 2: Order the labels

The required order is exactly **sort by (col, row, value)**. Sorting a list of triples with that comparator, then grouping consecutive equal columns, produces the answer.

Could we avoid a full sort? Columns range over at most `n` consecutive integers from `minCol` to `maxCol`, so we could bucket by column in O(n). Inside a column, a BFS already visits nodes in row order, but ties within the same row still need sorting by value. So some sorting remains either way; the simple full sort is O(n log n) and is what most solutions use.

## Step 3: The code

<!-- CODE:START -->

Full source: [`vertical_order_traversal.dart`](vertical_order_traversal.dart) (run it with `dart run`).

```dart
// Vertical Order Traversal of a Binary Tree (LeetCode 987 rules).
// Root at (row 0, col 0); left child (row + 1, col - 1); right child (row + 1, col + 1).
// Output columns left to right; within a column sort by row, then by value.
// Collect (col, row, value) triples with DFS, sort, group. O(n log n) time, O(n) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<List<int>> verticalTraversal(TreeNode? root) {
  final entries = <(int col, int row, int value)>[];
  void dfs(TreeNode? node, int row, int col) {
    if (node == null) return;
    entries.add((col, row, node.value));
    dfs(node.left, row + 1, col - 1);
    dfs(node.right, row + 1, col + 1);
  }

  dfs(root, 0, 0);
  entries.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
    return a.$3.compareTo(b.$3); // same cell: smaller value first
  });
  final result = <List<int>>[];
  int? currentCol;
  for (final (col, _, value) in entries) {
    if (col != currentCol) {
      result.add([]);
      currentCol = col;
    }
    result.last.add(value);
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `entries` holds Dart records `(col, row, value)`.
- The comparator compares column, then row, then value.
- The grouping loop starts a new inner list whenever the column changes. `currentCol` starts as null so the first entry always opens a group.

## Step 4: Dry run

First tree. DFS produces:

| node | (col, row) |
|---|---|
| 3 | (0, 0) |
| 9 | (-1, 1) |
| 20 | (1, 1) |
| 15 | (0, 2) |
| 7 | (2, 2) |

Sorted: `(-1,1,9), (0,0,3), (0,2,15), (1,1,20), (2,2,7)`. Grouped by column: `[9], [3, 15], [20], [7]`.

## Complexity

- Time: **O(n log n)** for the sort; the DFS is O(n).
- Space: **O(n)** for the entries, plus O(h) recursion.

## Edge cases

- Empty tree: `[]`.
- A skewed tree: every node in its own column.
- Several nodes in the same (row, col) cell: sorted by value.

## Common mistakes

- Using BFS order for ties when the problem says "sort by value" (or the reverse).
- Using DFS order within a column and forgetting to sort by row: DFS can visit a deeper node in a column before a shallower one.
- Grouping by column in a hash map and forgetting that map iteration order is not column order.

## Follow-ups you should be ready for

1. **Top view (Striver).** For each column, the node with the smallest row (BFS, first node seen per column).
2. **Bottom view.** For each column, the node with the largest row (BFS, last node seen per column).
3. **Vertical sum.** Sum values per column; a map from column to sum, O(n).

## What to remember

Give each node coordinates with one traversal, then the required order is just a sort on a tuple. Confirm the tie rule before coding.
