# Merging Linked Lists

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Two pointers that equalize path lengths

## The problem

Two singly linked lists may **merge**: from some node on, they share all remaining nodes (the same node objects, not just equal values). Return the first shared node, or null if they never merge. Do not modify the lists.

```
list one:  2 -> 3 \
                    1 -> 9 -> 10
list two:  8 -> 7 -> 6 /

->  the node with value 1
```

## Step 1: Hash set solution

Walk list one and put every **node** (by identity) in a set. Walk list two; the first node found in the set is the answer. **O(n + m) time, O(n) space.**

## Step 2: O(1) space: equalize the lengths

If both lists had the same length before the merge point, you could walk them in lockstep and they would reach the merge node at the same time. The lists differ in length only **before** the merge (the shared part is common). So:

1. Compute both lengths.
2. Advance the longer list's pointer by the difference.
3. Walk both together until the pointers are the same node (or both null).

O(n + m) time, O(1) space.

## Step 3: The elegant version (no length computation)

Pointer `a` walks list one, then continues from the head of list two. Pointer `b` walks list two, then continues from the head of list one.

Why do they meet at the merge node? Let list one have `x` nodes before the merge, list two `y` nodes before the merge, and `z` shared nodes. When `a` reaches the merge node for the second time around, it has walked `x + z + y` nodes; `b` has walked `y + z + x`. The same number. So they arrive together.

If the lists never merge (`z = 0`), both pointers reach null at the same moment (after `n + m` steps), and the loop ends with null.

## Step 4: The code

<!-- CODE:START -->

Full source: [`merging_linked_lists.dart`](merging_linked_lists.dart) (run it with `dart run`).

```dart
// Merging Linked Lists: return the node where two singly linked lists intersect, or null.
// Two pointers that switch to the other list's head at the end meet at the intersection
// after at most n + m steps. O(n + m) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;
}

LinkedList? mergingLinkedLists(LinkedList one, LinkedList two) {
  LinkedList? a = one, b = two;
  while (!identical(a, b)) {
    a = a == null ? two : a.next;
    b = b == null ? one : b.next;
  }
  return a; // the shared node, or null if both reached the end together
}
```

<!-- CODE:END -->

### Walkthrough

- `LinkedList? a = one, b = two;` start at both heads.
- `while (!identical(a, b))` loops until both point to the same node (or both are null).
- `a = a == null ? two : a.next;` switches to the other list's head after the end.
- `return a;` is the merge node or null.

## Step 5: Dry run

List one: `2, 3, 1, 9, 10` (x = 2, shared z = 3). List two: `8, 7, 6, 1, 9, 10` (y = 3).

| step | a | b |
|---|---|---|
| 0 | 2 | 8 |
| 1 | 3 | 7 |
| 2 | 1 | 6 |
| 3 | 9 | 1 |
| 4 | 10 | 9 |
| 5 | null | 10 |
| 6 | 8 (head of two) | null |
| 7 | 7 | 2 (head of one) |
| 8 | 6 | 3 |
| 9 | **1** | **1** |

They meet at node 1 on step 9. Each pointer walked its own list (including one step onto null) and then the other list's unshared prefix, so both covered the same distance.

## Complexity

- **Time: O(n + m)**.
- **Space: O(1)**.

## Common mistakes

- Comparing values instead of node identity (two different nodes can hold equal values).
- Switching to the **same** list's head instead of the other list's head.
- Infinite loop when there is no merge: avoided because both pointers hit null simultaneously on the second pass.

## Follow-ups

1. **Intersection of Two Linked Lists (LeetCode #160):** identical.
2. **Lists that might have cycles:** first detect cycles (Find Loop, hard 35); the analysis splits into cases.
3. **Youngest Common Ancestor (medium 39):** the same problem viewed on a tree with parent pointers.

## What to remember

Two pointers that each traverse both lists travel equal distances and meet at the intersection.
