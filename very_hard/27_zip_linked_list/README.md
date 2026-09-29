# Zip Linked List

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Split + reverse + interleave

## The problem

Rearrange a singly linked list `1 -> 2 -> ... -> n` **in place** into:

```
1 -> n -> 2 -> n-1 -> 3 -> n-2 -> ...

1 -> 2 -> 3 -> 4 -> 5 -> 6   =>   1 -> 6 -> 2 -> 5 -> 3 -> 4
1 -> 2 -> 3 -> 4 -> 5        =>   1 -> 5 -> 2 -> 4 -> 3
```

## Step 1: Easy version with extra space

Put all node references in an array and use two pointers from both ends to relink them: O(n) space.

## Step 2: See the structure of the output

The output alternates between:

- the **first half** in order: 1, 2, 3, ...
- the **second half** in reverse: n, n-1, ...

A singly linked list cannot be walked backward, but it can be **reversed**. So:

1. find the middle (the first half keeps the extra node for odd lengths);
2. **cut** the list after the middle;
3. **reverse** the second half;
4. **interleave** the two lists node by node.

## Step 3: The code

<!-- CODE:START -->

Full source: [`zip_linked_list.dart`](zip_linked_list.dart) (run it with `dart run`).

```dart
// Zip Linked List: 1 -> n -> 2 -> n-1 -> 3 -> ... in place.
// Split at the middle, reverse the second half, interleave. O(n) time, O(1) space.

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

LinkedList zipLinkedList(LinkedList head) {
  if (head.next == null || head.next!.next == null) return head;
  // First half keeps the extra node for odd lengths.
  var slow = head;
  LinkedList? fast = head;
  while (fast!.next != null && fast.next!.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  LinkedList? second = _reverse(slow.next!);
  slow.next = null;
  LinkedList? first = head;
  while (first != null && second != null) {
    final firstNext = first.next, secondNext = second.next;
    first.next = second;
    second.next = firstNext;
    first = firstNext;
    second = secondNext;
  }
  return head;
}

LinkedList _reverse(LinkedList head) {
  LinkedList? prev;
  LinkedList? cur = head;
  while (cur != null) {
    final next = cur.next;
    cur.next = prev;
    prev = cur;
    cur = next;
  }
  return prev!;
}
```

<!-- CODE:END -->

### Walkthrough

- Lists of length 1 or 2 are returned as they are.
- The slow/fast loop condition `fast.next != null && fast.next.next != null` stops `slow` at the end of the first half.
- `_reverse(slow.next!)` reverses the second half; `slow.next = null` cuts the list.
- The interleave loop saves both `next` pointers **before** relinking, then links `first -> second -> firstNext`.

## Step 4: Dry run: `1 -> 2 -> 3 -> 4 -> 5 -> 6`

| step | result |
|---|---|
| middle | slow stops at 3 |
| cut | first: 1 -> 2 -> 3, second: 4 -> 5 -> 6 |
| reverse second | 6 -> 5 -> 4 |
| interleave | 1 -> 6 -> 2 -> 5 -> 3 -> 4 |

For `1 -> 2 -> 3 -> 4 -> 5`: first `1 -> 2 -> 3`, second reversed `5 -> 4`, result `1 -> 5 -> 2 -> 4 -> 3`.

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Not cutting the list (the first half still points into the second half, creating a cycle after interleaving).
- Losing the `next` pointers during the interleave.
- A middle that gives the extra node to the second half (the order at the end comes out wrong).

## Follow-ups

1. **Reorder List (LeetCode #143):** identical.
2. **Linked List Palindrome (very hard 26):** the same first three steps.
3. Test with lengths 1, 2, 3, 4, and 5: they cover every middle-finding edge case.

## What to remember

Output that alternates "front, back, front, back" = split in the middle, reverse the second half, interleave.
