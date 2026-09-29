# Reverse Linked List

**Difficulty:** Hard (on AlgoExpert; Easy on LeetCode) | **Category:** Linked Lists | **Pattern:** Pointer reversal

## The problem

Reverse a singly linked list **in place** and return its new head.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5      =>      5 -> 4 -> 3 -> 2 -> 1 -> 0
```

## Step 1: Work an example by hand

Draw `0 -> 1 -> 2`. To reverse it, every arrow must point the other way: `0 <- 1 <- 2`. Walk the list and flip one arrow at a time:

- At node 0: make it point to "nothing" (it becomes the tail).
- At node 1: make it point to 0.
- At node 2: make it point to 1. Node 2 is the new head.

The catch: when you flip `1.next` from 2 to 0, you **lose** your only way to reach node 2. So save `next` **before** flipping.

## Step 2: Three pointers

```
prev = null
current = head
while current != null:
    next = current.next      # 1. save the rest of the list
    current.next = prev      # 2. flip the arrow
    prev = current           # 3. advance prev
    current = next           # 4. advance current
return prev                  # the old tail, now the head
```

The order of these four lines matters. Say it out loud: save, flip, advance, advance.

## Step 3: Recursive version

Reverse everything after the head, then fix two pointers:

```
reverse(head):
    if head.next is null: return head        # a single node is its own reverse
    newHead = reverse(head.next)
    head.next.next = head                    # the old second node points back to head
    head.next = null                         # head becomes the tail
    return newHead
```

Elegant, but it uses O(n) call-stack space, and very long lists overflow the stack.

## Step 4: The code

<!-- CODE:START -->

Full source: [`reverse_linked_list.dart`](reverse_linked_list.dart) (run it with `dart run`).

```dart
// Reverse Linked List in place. Three pointers. O(n) time, O(1) space.

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

LinkedList reverseLinkedList(LinkedList head) {
  LinkedList? prev;
  LinkedList? current = head;
  while (current != null) {
    final next = current.next; // save before overwriting
    current.next = prev;
    prev = current;
    current = next;
  }
  return prev!;
}

/// Recursive version: O(n) stack space.
LinkedList reverseRecursive(LinkedList head) {
  final rest = head.next;
  if (rest == null) return head;
  final newHead = reverseRecursive(rest);
  rest.next = head; // the old next is now the tail of the reversed rest
  head.next = null;
  return newHead;
}
```

<!-- CODE:END -->

### Walkthrough

- `reverseLinkedList` is the iterative three-pointer version.
- `reverseRecursive` follows Step 3. `rest` is the old second node; after the recursive call it is the **tail** of the reversed remainder, so `rest.next = head` appends the old head.

## Step 5: Dry run (iterative, `0 -> 1 -> 2`)

| step | prev | current | next saved | list state |
|---|---|---|---|---|
| start | null | 0 | | 0 -> 1 -> 2 |
| 1 | 0 | 1 | 1 | null <- 0   1 -> 2 |
| 2 | 1 | 2 | 2 | null <- 0 <- 1   2 |
| 3 | 2 | null | null | null <- 0 <- 1 <- 2 |

Return `prev` = node 2.

## Complexity

- **Time: O(n)**.
- **Space: O(1)** iterative, O(n) recursive.

## Common mistakes

- Flipping `current.next` before saving it (the rest of the list is lost).
- Returning `current` (null at the end) instead of `prev`.
- In the recursive version, forgetting `head.next = null` (creates a 2-node cycle).

## Where this is a building block

- **Linked List Palindrome (very hard 26)** and **Zip Linked List (very hard 27):** reverse the second half.
- **Reverse Linked List II (LeetCode #92):** reverse only positions m..n.
- **Reverse Nodes in k-Group (#25):** reverse each block of k nodes.
- **Add Two Numbers II (#445):** reverse inputs to add from the least significant digit.

## What to remember

Save next, flip the arrow, advance both pointers. Practice until you can write it bug-free in under a minute.
