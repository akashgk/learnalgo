# Middle Node

**Difficulty:** Easy | **Category:** Linked Lists | **Pattern:** Fast and slow pointers

## The problem

Given the head of a non-empty singly linked list, return its middle node. If the list has an even number of nodes, there are two middle nodes; return the **second** one.

```
1 -> 2 -> 3              ->  node 2
2 -> 7 -> 3 -> 5         ->  node 3   (middles are 7 and 3; return the second)
```

## Step 1: Work an example by hand

With an array you would compute `length ~/ 2` and index directly. A linked list has no indexing and no stored length. You can only walk forward one node at a time.

The obvious fix: walk once to count, walk again to the middle. That works. Can we do it in one walk?

Imagine two runners on the list. One takes two steps each turn, the other takes one. When the fast runner reaches the end, the slow runner has covered exactly half the distance: it is standing on the middle.

## Step 2: Two-pass solution

```dart
var length = 0;
for (LinkedList? n = head; n != null; n = n.next) length++;
var node = head;
for (var i = 0; i < length ~/ 2; i++) node = node.next!;
return node;
```

O(n) time, O(1) space. This is a perfectly good answer, and it is worth giving first. For length 4 it walks 2 steps from the head and returns the third node, which is the second middle, as required.

## Step 3: One pass with fast and slow pointers

- `slow` moves one node per step, `fast` moves two.
- Keep going while `fast` can make a full double step: `fast != null && fast.next != null`.
- When the loop stops, `slow` is the middle.

The loop condition is the part people get wrong, so verify it on small lengths:

| length | list | where fast stops | slow ends on |
|---|---|---|---|
| 1 | a | a (fast.next is null) | a |
| 2 | a b | null after one step | b (second middle) |
| 3 | a b c | c | b |
| 4 | a b c d | null after two steps | c (second middle) |

If you ever need the **first** middle for even lengths, start `fast` at `head.next` instead.

## Step 4: The code

<!-- CODE:START -->

Full source: [`middle_node.dart`](middle_node.dart) (run it with `dart run`).

```dart
// Middle Node
// Slow/fast pointers: fast moves 2, slow moves 1. When fast finishes, slow is in the middle.
// For even length this returns the second of the two middle nodes. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;

  static LinkedList? fromList(List<int> values) {
    LinkedList? head;
    for (final v in values.reversed) {
      head = LinkedList(v, head);
    }
    return head;
  }
}

LinkedList middleNode(LinkedList linkedList) {
  var slow = linkedList;
  LinkedList? fast = linkedList;
  while (fast != null && fast.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  return slow;
}
```

<!-- CODE:END -->

### Walkthrough

- `var slow = linkedList;` is non-nullable: slow never passes the middle, so it never becomes null.
- `LinkedList? fast = linkedList;` is nullable because fast can step off the end.
- `while (fast != null && fast.next != null)` guarantees `fast.next!.next` is safe to read.
- `slow = slow.next!; fast = fast.next!.next;` is one step for slow, two for fast.

## Step 5: Dry run

`2 -> 7 -> 3 -> 5`:

| step | slow | fast | continue? |
|---|---|---|---|
| start | 2 | 2 | fast and fast.next exist: yes |
| 1 | 7 | 3 | yes |
| 2 | 3 | null | no |

Return node `3`.

## Complexity

- **Time: O(n)**: fast walks the list once (n/2 iterations).
- **Space: O(1)**.

Both versions have the same big-O and do about the same number of node visits (the two-pass version walks n + n/2 nodes; the one-pass version moves its pointers about n/2 + n times). The real value of fast and slow pointers is as a **building block**: the same technique detects cycles and splits lists where a length count does not help.

## Common mistakes

- Loop condition `while (fast.next != null)` without checking `fast` itself: crashes for even lengths.
- Returning the first middle when the problem asks for the second (or vice versa).

## Follow-ups

1. **Find Loop (hard 35):** if fast ever meets slow, there is a cycle; a second phase finds its start.
2. **Linked List Palindrome (very hard 26)** and **Zip Linked List (very hard 27):** find the middle, reverse the second half, then compare or interleave.
3. **Delete the middle node (LeetCode #2095):** stop slow one node earlier (keep a `prev`).

## What to remember

Two pointers at different speeds find positions proportional to the length (middle, cycles) in one pass with O(1) space. Always test the loop condition on lengths 1 through 4.
