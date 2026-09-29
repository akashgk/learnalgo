# Repair BST

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** In-order traversal to locate inversions

## The problem

Exactly **two** nodes of a BST had their values swapped by mistake, so the tree no longer satisfies the BST property. Repair it **in place** (swap the two values back) and return the root.

```
broken:                 repaired:
        10                      10
       /  \                    /  \
     20    7                  7    20
    /  \  / \                / \   / \
   2   8 14  22             2   8 14  22
  /                        /
 1                        1

(7 and 20 were swapped)
```

## Step 1: Use the sorted-order property

An in-order traversal of a valid BST produces a **sorted** sequence. For the broken tree, the in-order sequence is:

```
1, 2, 20, 8, 10, 14, 7, 22
```

The swapped values stick out as **inversions**: places where a value is bigger than the next one.

- `20 > 8`: the first inversion. The misplaced value is the **bigger** one, 20 (it moved left).
- `14 > 7`: the second inversion. The misplaced value is the **smaller** one, 7 (it moved right).

Swap 20 and 7 back and the sequence (and the tree) is sorted again.

## Step 2: The adjacent case

If the two swapped values are **next to each other** in sorted order, there is only **one** inversion: `1, 3, 2, 4` has only `3 > 2`. Both misplaced values are in that single inversion: the bigger (first) and the smaller (second).

A uniform rule handles both cases:

- `first` = the **first** element (the bigger one) of the **first** inversion;
- `second` = the **second** element (the smaller one) of the **last** inversion.

In code: set `first` only once; update `second` at every inversion.

## Step 3: Traverse without building the array

Collecting all values in an array works (O(n) space). Instead, do the in-order traversal and remember only the **previous** node visited. Each time `prev.value > current.value`, you found an inversion.

## Step 4: The code

<!-- CODE:START -->

Full source: [`repair_bst.dart`](repair_bst.dart) (run it with `dart run`).

```dart
// Repair BST: exactly two nodes had their values swapped. Find them via in-order traversal
// (the only inversions in the sequence) and swap back. O(n) time, O(h) space.

class BST {
  BST(this.value, [this.left, this.right]);
  int value;
  BST? left;
  BST? right;
}

BST repairBst(BST tree) {
  BST? first, second, prev;
  final stack = <BST>[];
  BST? node = tree;
  while (node != null || stack.isNotEmpty) {
    while (node != null) {
      stack.add(node);
      node = node.left;
    }
    final current = stack.removeLast();
    if (prev != null && prev.value > current.value) {
      first ??= prev; // first inversion: the bigger (earlier) element is misplaced
      second = current; // last inversion: the smaller (later) element is misplaced
    }
    prev = current;
    node = current.right;
  }
  final tmp = first!.value;
  first.value = second!.value;
  second.value = tmp;
  return tree;
}

List<int> inOrder(BST? t) => t == null ? [] : [...inOrder(t.left), t.value, ...inOrder(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- Iterative in-order traversal with an explicit stack (push all left children, pop, visit, go right).
- `if (prev != null && prev.value > current.value)` detects an inversion.
- `first ??= prev;` records the first inversion's bigger node only once.
- `second = current;` always takes the latest inversion's smaller node.
- Finally the two values are swapped. Swapping values (not nodes) keeps the tree structure unchanged.

## Step 5: Dry run

In-order: `1, 2, 20, 8, 10, 14, 7, 22`.

| prev | current | inversion? | first | second |
|---|---|---|---|---|
| 1 | 2 | no | | |
| 2 | 20 | no | | |
| 20 | 8 | **yes** | 20 | 8 |
| 8 | 10 | no | 20 | 8 |
| 10 | 14 | no | | |
| 14 | 7 | **yes** | 20 (unchanged) | 7 |
| 7 | 22 | no | | |

Swap 20 and 7.

## Complexity

- **Time: O(n)**.
- **Space: O(h)** for the traversal stack. **Morris traversal** (temporarily threading right pointers of in-order predecessors) makes it O(1); that is the LeetCode #99 follow-up.

## Common mistakes

- Taking both nodes from the first inversion (wrong when the swap is not adjacent).
- Taking the first element of the second inversion (it should be the second element).
- Missing the adjacent case (only one inversion exists).

## What to remember

In-order traversal of a BST is sorted; a swapped pair creates one or two inversions. Take the bigger element of the first inversion and the smaller element of the last.
