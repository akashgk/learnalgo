# Morris Inorder Traversal

**Difficulty:** Medium | **Category:** Binary trees | **Pattern:** Threaded binary tree (temporary links) | **Source:** Striver A2Z (Morris traversal); LeetCode 94 with an O(1)-space follow-up

## The problem

Return the inorder traversal of a binary tree using **O(1) extra space**: no recursion and no explicit stack. The tree may be modified temporarily but must be restored.

```
        4
      /   \
     2     6        ->  [1, 2, 3, 4, 5, 6, 7]
    / \   / \
   1   3 5   7
```

## Step 1: Why normal traversals need O(h) space

Inorder visits the left subtree, then the node, then the right subtree. After finishing the left subtree, you need to **get back up** to the node. Recursion (the call stack) or an explicit stack remembers the way back, costing O(h) memory, O(n) for a skewed tree.

## Step 2: Where could the "way back" be stored for free?

After the left subtree of `cur` is finished, the **last node visited** is the **inorder predecessor** of `cur`: the rightmost node of `cur`'s left subtree. That node's `right` pointer is **null** (it is the rightmost). An unused pointer is free storage.

**Idea:** before descending into the left subtree, set `predecessor.right = cur`. This temporary link is a **thread**. When the traversal later finishes the left subtree, it follows the predecessor's `right` pointer as if it were a normal right child, and arrives back at `cur`. Then remove the thread to restore the tree.

## Step 3: How do we know if we are arriving the first or second time?

At `cur` with a left child, walk to the rightmost node of the left subtree, **stopping if you reach a node whose `right` is already `cur`**:

- `pred.right == null`: first arrival. Create the thread and go left.
- `pred.right == cur`: second arrival, via the thread. The left subtree is done: remove the thread, **visit** `cur`, go right.

If `cur` has no left child, visit it and go right (that "right" may be a thread leading back up).

## Step 4: The code

<!-- CODE:START -->

Full source: [`morris_inorder_traversal.dart`](morris_inorder_traversal.dart) (run it with `dart run`).

```dart
// Morris Inorder Traversal: inorder traversal in O(1) extra space (no stack, no recursion).
// Temporarily thread each node's inorder predecessor back to it, then remove the thread.
// O(n) time (each edge is walked at most a constant number of times), O(1) space.

class TreeNode {
  TreeNode(this.value, [this.left, this.right]);
  int value;
  TreeNode? left;
  TreeNode? right;
}

List<int> morrisInorder(TreeNode? root) {
  final result = <int>[];
  var cur = root;
  while (cur != null) {
    if (cur.left == null) {
      // Nothing on the left: visit and go right (possibly along a thread).
      result.add(cur.value);
      cur = cur.right;
      continue;
    }
    // Predecessor = rightmost node of the left subtree (stop if it already threads back to cur).
    var pred = cur.left!;
    while (pred.right != null && pred.right != cur) {
      pred = pred.right!;
    }
    if (pred.right == null) {
      // First visit: create the thread, then explore the left subtree.
      pred.right = cur;
      cur = cur.left;
    } else {
      // Second visit (came back through the thread): left subtree is done.
      pred.right = null; // restore the tree
      result.add(cur.value);
      cur = cur.right;
    }
  }
  return result;
}

List<int> recursiveInorder(TreeNode? t) =>
    t == null ? [] : [...recursiveInorder(t.left), t.value, ...recursiveInorder(t.right)];
```

<!-- CODE:END -->

### Walkthrough

- The inner `while` finds the predecessor. The condition `pred.right != cur` is essential; without it, a thread would be followed back to `cur` in an infinite loop.
- Creating a thread and removing it happen at the two arrivals at `cur`.
- After the loop, every thread has been removed; the test `recursiveInorder(t)` after `morrisInorder(t)` verifies the tree is intact.

## Step 5: Dry run

Tree above. Threads are written `x -> y`:

| cur | left? | predecessor | action | output |
|---|---|---|---|---|
| 4 | yes | 3 (right null) | thread 3 -> 4, go left | |
| 2 | yes | 1 (right null) | thread 1 -> 2, go left | |
| 1 | no | | visit, go right (thread to 2) | 1 |
| 2 | yes | 1 (right is 2) | remove thread, visit, go right | 2 |
| 3 | no | | visit, go right (thread to 4) | 3 |
| 4 | yes | 3 (right is 4) | remove thread, visit, go right | 4 |
| 6 | yes | 5 (right null) | thread 5 -> 6, go left | |
| 5 | no | | visit, go right (thread to 6) | 5 |
| 6 | yes | 5 (right is 6) | remove thread, visit, go right | 6 |
| 7 | no | | visit, go right (null) | 7 |

## Complexity

- Time: **O(n)**. Finding predecessors looks like extra work, but each edge of the tree is walked at most a constant number of times (about twice for the predecessor searches, once per thread use), so the total is linear.
- Space: **O(1)** extra.

## Edge cases

- Empty tree.
- Only left children (a chain): each node threads its predecessor on the way down.
- Only right children: no threads are ever created.

## Common mistakes

- Missing the `pred.right != cur` stop condition (infinite loop).
- Visiting `cur` on the first arrival (that gives **preorder**, see below) when inorder was asked.
- Forgetting to remove threads, leaving the tree corrupted (and cyclic).

## Follow-ups you should be ready for

1. **Morris preorder.** Visit `cur` when **creating** the thread (first arrival), and when there is no left child.
2. **Kth smallest in a BST, or validate a BST, in O(1) space.** Run Morris inorder and stop early (restoring any remaining threads if you stop in the middle, or finishing the walk).
3. **Recover a BST with two swapped nodes (AlgoExpert hard 11 Repair BST) in O(1) space.** Morris inorder while tracking the previous node.
4. **Is it thread safe?** No: the tree is temporarily modified, so concurrent readers can see threads.

## What to remember

The inorder predecessor's null right pointer is free memory. Point it back to the current node so you can return without a stack, and erase it on the way back.
