# Merge Linked Lists

**Difficulty:** Hard (on AlgoExpert; Easy on LeetCode) | **Category:** Linked Lists | **Pattern:** Merge step with a dummy head

## The problem

Given the heads of two **sorted** singly linked lists, merge them **in place** into one sorted list (reuse the existing nodes; do not create new ones) and return the head of the merged list.

```
2 -> 6 -> 7 -> 8
1 -> 3 -> 4 -> 5 -> 9 -> 10
=>  1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10
```

## Step 1: The merge step of merge sort

With two sorted piles of cards face up, you repeatedly take the smaller of the two top cards. The same works for linked lists, except that "taking" a node means **linking** it to the end of the result.

## Step 2: The dummy head trick

Which node is the head of the result? It depends on which list has the smaller first value. That creates a special case for the very first node. Instead, create a **dummy** node and always append after a `tail` pointer that starts at the dummy. At the end, return `dummy.next`.

Dummy (sentinel) nodes remove special cases in almost every linked-list problem where the head can change.

## Step 3: The algorithm

```
dummy = new node; tail = dummy
while a != null and b != null:
    if a.value <= b.value: tail.next = a; a = a.next
    else:                  tail.next = b; b = b.next
    tail = tail.next
tail.next = a ?? b          # attach whatever remains, in O(1)
return dummy.next
```

When one list runs out, the rest of the other list is already sorted and can be attached **as is**, with one pointer assignment. No need to walk it.

## Step 4: The code

<!-- CODE:START -->

Full source: [`merge_linked_lists.dart`](merge_linked_lists.dart) (run it with `dart run`).

```dart
// Merge Linked Lists: merge two sorted lists in place (relinking nodes, no new nodes).
// Dummy head + tail pointer. O(n + m) time, O(1) space.

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

LinkedList mergeLinkedLists(LinkedList headOne, LinkedList headTwo) {
  final dummy = LinkedList(0);
  var tail = dummy;
  LinkedList? a = headOne, b = headTwo;
  while (a != null && b != null) {
    if (a.value <= b.value) {
      tail.next = a;
      a = a.next;
    } else {
      tail.next = b;
      b = b.next;
    }
    tail = tail.next!;
  }
  tail.next = a ?? b; // attach whatever remains
  return dummy.next!;
}
```

<!-- CODE:END -->

### Walkthrough

- `final dummy = LinkedList(0);` is never part of the answer; `tail` starts at it.
- The loop links the smaller front node and advances that list.
- `<=` takes from the first list on ties, which keeps the merge **stable**.
- `tail.next = a ?? b;` attaches the remainder.

## Step 5: Dry run (first steps)

| a | b | take | result so far |
|---|---|---|---|
| 2 | 1 | 1 (b) | 1 |
| 2 | 3 | 2 (a) | 1 -> 2 |
| 6 | 3 | 3 (b) | 1 -> 2 -> 3 |
| 6 | 4 | 4 (b) | ... -> 4 |
| 6 | 5 | 5 (b) | ... -> 5 |
| 6 | 9 | 6 (a) | ... -> 6 |
| 7 | 9 | 7 (a) | ... -> 7 |
| 8 | 9 | 8 (a) | ... -> 8 |
| null | 9 | attach 9 -> 10 | done |

## Complexity

- **Time: O(n + m)**.
- **Space: O(1)** (a recursive version uses O(n + m) stack).

## Common mistakes

- Special-casing the first node instead of using a dummy.
- Walking the leftover list node by node instead of attaching it.
- Creating new nodes when the problem asks to merge in place.

## Follow-ups

1. **Merge Two Sorted Lists (LeetCode #21).**
2. **Merge k Sorted Lists (#23):** a min-heap of list heads, or pairwise divide-and-conquer merging: O(N log k). See Merge Sorted Arrays (very hard 23).
3. **Sort List (#148):** merge sort on a linked list: split with fast/slow pointers, sort both halves, merge with this function. O(n log n) time.

## What to remember

Use a dummy head, always link the smaller front node, and attach the leftover list in one step.
