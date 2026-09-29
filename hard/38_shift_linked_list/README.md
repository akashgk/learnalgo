# Shift Linked List

**Difficulty:** Hard | **Category:** Linked Lists | **Pattern:** Length + modular offset + relink

## The problem

Shift a singly linked list **in place** by `k` positions and return the new head:

- positive `k`: shift **forward**: the last k nodes move to the front;
- negative `k`: shift **backward**: the first |k| nodes move to the end.

`k` may be larger than the length.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5, k = 2    =>  4 -> 5 -> 0 -> 1 -> 2 -> 3
0 -> 1 -> 2 -> 3 -> 4 -> 5, k = -2   =>  2 -> 3 -> 4 -> 5 -> 0 -> 1
```

## Step 1: Reduce k

Shifting a list of length n by n positions changes nothing. So only `k mod n` matters: shifting by 8 is the same as shifting by 2 for n = 6.

A backward shift by m is the same as a forward shift by `n - m`: shifting back by 2 equals shifting forward by 4 when n = 6. If the modulo operation always returns a non-negative result (Dart's `%` does), then `k % n` handles both directions at once: `-2 % 6 == 4`. In Java or C++, use `((k % n) + n) % n`.

## Step 2: Where to cut

For a forward shift by `offset` (1 <= offset < n):

- the **new tail** is the node at index `n - offset - 1`,
- the **new head** is the node after it,
- the **old tail** must point to the **old head**.

For `0..5` and offset 2: new tail at index 3 (node 3), new head node 4. Cut after 3, link 5 -> 0.

## Step 3: Algorithm

1. Walk once to find the length and the old tail.
2. `offset = k % length`; if 0, return the head unchanged.
3. Walk to the new tail (`length - offset - 1` steps).
4. `newHead = newTail.next; newTail.next = null; oldTail.next = oldHead`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`shift_linked_list.dart`](shift_linked_list.dart) (run it with `dart run`).

```dart
// Shift Linked List by k (positive: move tail nodes to the front; negative: move head nodes
// to the back). Find length and tail, cut at the right spot, reconnect.
// O(n) time, O(1) space.

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

LinkedList shiftLinkedList(LinkedList head, int k) {
  var length = 1;
  var tail = head;
  while (tail.next != null) {
    tail = tail.next!;
    length++;
  }
  final offset = k % length; // Dart % is non-negative: -1 % 6 == 5, i.e. shift forward by 5
  if (offset == 0) return head;
  // New tail is at position length - offset - 1 (0-based).
  var newTail = head;
  for (var i = 0; i < length - offset - 1; i++) {
    newTail = newTail.next!;
  }
  final newHead = newTail.next!;
  newTail.next = null;
  tail.next = head;
  return newHead;
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop counts `length` and leaves `tail` at the last node.
- `final offset = k % length;` normalizes both signs.
- The second loop reaches the new tail.
- Three pointer assignments finish the rotation.

## Step 5: Dry run (k = -1, list 0..5)

`offset = -1 % 6 = 5`. New tail index `6 - 5 - 1 = 0` (node 0), new head node 1. Cut after 0, link 5 -> 0. Result: `1 -> 2 -> 3 -> 4 -> 5 -> 0`. Correct: the first node moved to the end.

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Not reducing k (walking k steps when k is huge).
- Negative modulo in languages where `%` can be negative.
- Forgetting to terminate the new tail (`newTail.next = null`), which creates a cycle.

## Follow-ups

1. **Rotate List (LeetCode #61):** positive k only.
2. **Alternative:** connect the tail to the head to form a ring, walk to the new tail, and break the ring there.
3. **Rotate an array (#189):** reverse all, then reverse the two parts.

## What to remember

Normalize the shift with a non-negative modulo, find the cut point by index, and relink three pointers.
