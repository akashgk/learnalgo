# Rearrange Linked List

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Stable partition into sublists with dummy heads

## The problem

Given a singly linked list and an integer k, rearrange the list **in place** so that:

1. all nodes with values **less than k** come first,
2. then all nodes **equal to k**,
3. then all nodes **greater than k**,

keeping the **original relative order** within each group. Return the new head. k may not appear in the list.

```
3 -> 0 -> 5 -> 2 -> 1 -> 4, k = 3
=>  0 -> 2 -> 1 -> 3 -> 5 -> 4
```

## Step 1: Why not swap values?

You could copy values into an array, do a stable partition, and write them back, but that uses O(n) space and does not move nodes. The problem asks to rearrange the nodes in place.

## Step 2: Three lists, one pass

Walk the list once and **move each node to the end of one of three new lists** (less, equal, greater) depending on its value. Appending to the end preserves the original order within each group, so the partition is **stable**.

Then connect: less -> equal -> greater.

## Step 3: Details that make it bug-free

- **Dummy heads** for each of the three lists: appending the first node is then no different from appending any other.
- **Detach** each node as you move it (`node.next = null`), after saving the original next pointer. This prevents old links from creating cycles.
- **Empty groups:** when joining, skip empty lists. The new head is the first node of the first non-empty group.
- The last list's tail must end with null.

## Step 4: The code

<!-- CODE:START -->

Full source: [`rearrange_linked_list.dart`](rearrange_linked_list.dart) (run it with `dart run`).

```dart
// Rearrange Linked List around k: nodes < k, then == k, then > k, keeping relative order
// within each group (stable). Three sublists joined at the end. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;

  static LinkedList fromList(List<int> values) {
    LinkedList? head;
    for (final v in values.reversed) {
      head = LinkedList(v, head);
    }
    return head!;
  }

  List<int> toList() => [for (LinkedList? n = this; n != null; n = n.next) n.value];
}

LinkedList rearrangeLinkedList(LinkedList head, int k) {
  final lessHead = LinkedList(0), equalHead = LinkedList(0), greaterHead = LinkedList(0);
  var less = lessHead, equal = equalHead, greater = greaterHead;
  LinkedList? node = head;
  while (node != null) {
    final next = node.next;
    node.next = null;
    if (node.value < k) {
      less = less.next = node;
    } else if (node.value == k) {
      equal = equal.next = node;
    } else {
      greater = greater.next = node;
    }
    node = next;
  }
  greater.next = null;
  equal.next = greaterHead.next;
  less.next = equalHead.next ?? greaterHead.next;
  return lessHead.next ?? equalHead.next ?? greaterHead.next!;
}
```

<!-- CODE:END -->

### Walkthrough

- `lessHead`, `equalHead`, `greaterHead` are dummies; `less`, `equal`, `greater` are their tails.
- `less = less.next = node;` appends and advances the tail in one statement (assignment is right-associative).
- The joins handle empty groups with `??`:
  - `equal.next = greaterHead.next;`
  - `less.next = equalHead.next ?? greaterHead.next;`
- The head is the first non-empty group's first node.

## Step 5: Dry run

`3 -> 0 -> 5 -> 2 -> 1 -> 4`, k = 3:

| node | group | less | equal | greater |
|---|---|---|---|---|
| 3 | equal | | 3 | |
| 0 | less | 0 | 3 | |
| 5 | greater | 0 | 3 | 5 |
| 2 | less | 0, 2 | 3 | 5 |
| 1 | less | 0, 2, 1 | 3 | 5 |
| 4 | greater | 0, 2, 1 | 3 | 5, 4 |

Joined: `0 -> 2 -> 1 -> 3 -> 5 -> 4`.

## Complexity

- **Time: O(n)**.
- **Space: O(1)** (three dummy nodes and a few pointers).

## Common mistakes

- Forgetting to terminate the last list (creates a cycle back into the old structure).
- Wrong joining when the "equal" group is empty (connecting less directly to greater must still work).

## Follow-ups

1. **Partition List (LeetCode #86):** two groups (less than x, and the rest).
2. **Odd Even Linked List (#328):** partition by position instead of value, same technique.
3. **Sort List (#148):** partitioning is also the core of quicksort on linked lists.

## What to remember

To partition a linked list stably, move nodes into separate lists with dummy heads, then join the non-empty lists.
