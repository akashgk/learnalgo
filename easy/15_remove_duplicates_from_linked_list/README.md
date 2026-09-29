# Remove Duplicates From Linked List

**Difficulty:** Easy | **Category:** Linked Lists | **Pattern:** Pointer skipping

## The problem

You get the head of a singly linked list whose values are sorted in ascending order. Remove nodes so that each value appears only once, **in place**, and return the head.

```
1 -> 1 -> 3 -> 4 -> 4 -> 4 -> 5 -> 6 -> 6
=>
1 -> 3 -> 4 -> 5 -> 6
```

### Clarifying questions

- Is the list sorted? (Yes. That is what makes duplicates adjacent.)
- Keep the first occurrence of each value? (Yes. This means the head never changes.)
- Unsorted version? (Then you need a hash set; see Follow-ups.)

## Step 1: Work an example by hand

Draw the list as boxes and arrows. Stand on the first `1`. The next box is also `1`: it must go. The one after is `3`, which differs. So redraw the arrow from the first `1` straight to `3`; the second `1` is no longer reachable and is gone.

Now stand on `3`. Next is `4`, different: keep it and move on. Stand on the first `4`. Skip the next two `4`s, point to `5`. And so on.

In a linked list, "deleting" a node just means **changing an arrow so nobody points to it anymore**.

## Step 2: The approach

For each node `current`:

1. Starting from `current.next`, skip forward while the value equals `current.value`. Call the first different node `nextDistinct` (it may be `null`).
2. Set `current.next = nextDistinct`.
3. Move `current` to `nextDistinct`.

No extra data structure is needed, because sorting guarantees all copies of a value are adjacent.

## Step 3: The code

<!-- CODE:START -->

Full source: [`remove_duplicates_from_linked_list.dart`](remove_duplicates_from_linked_list.dart) (run it with `dart run`).

```dart
// Remove Duplicates From Linked List (sorted list).
// For each node, skip all following nodes with the same value. O(n) time, O(1) space.

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

  List<int> toList() => [for (LinkedList? n = this; n != null; n = n.next) n.value];
}

LinkedList removeDuplicatesFromLinkedList(LinkedList linkedList) {
  LinkedList? current = linkedList;
  while (current != null) {
    var nextDistinct = current.next;
    while (nextDistinct != null && nextDistinct.value == current.value) {
      nextDistinct = nextDistinct.next;
    }
    current.next = nextDistinct;
    current = nextDistinct;
  }
  return linkedList;
}
```

<!-- CODE:END -->

### Walkthrough

- `LinkedList? current = linkedList;` starts at the head.
- The inner `while` finds the first node with a different value. It also stops at `null`, which handles duplicates at the very end of the list.
- `current.next = nextDistinct;` is the actual deletion: one pointer change removes a whole run of duplicates.
- `current = nextDistinct;` jumps straight to the next distinct value. The outer loop never revisits skipped nodes.
- `return linkedList;` returns the same head, since the first node is always kept.
- `fromList` / `toList` are test helpers that convert between Dart lists and linked lists.

## Step 4: Dry run

List `1 -> 1 -> 3 -> 4 -> 4 -> 4 -> 5 -> 6 -> 6`:

| current | skipped nodes | nextDistinct | list so far |
|---|---|---|---|
| 1 | 1 | 3 | 1 -> 3 -> ... |
| 3 | none | 4 | 1 -> 3 -> 4 -> ... |
| 4 | 4, 4 | 5 | 1 -> 3 -> 4 -> 5 -> ... |
| 5 | none | 6 | ... 5 -> 6 -> ... |
| 6 | 6 | null | 1 -> 3 -> 4 -> 5 -> 6 |

## Complexity

- **Time: O(n)**. Although there are two nested loops, every node is visited by exactly one of them once: the inner loop moves forward, and the outer loop continues from where the inner loop stopped.
- **Space: O(1)**. Only pointers.

## Edge cases

- All values equal (`2 -> 2 -> 2`): becomes `2`.
- No duplicates: unchanged.
- Duplicates at the tail: `nextDistinct` becomes `null`, terminating the list correctly.

## Common mistakes

- Moving `current` forward after every node instead of jumping to `nextDistinct`. With a single-step loop, you must only advance when the next value is different, or you skip checks.
- Forgetting the `nextDistinct != null` check (null dereference at the tail).

## Follow-ups

1. **Unsorted list:** keep a hash set of seen values and remove any node whose value is already in the set. O(n) time, O(n) space. Without extra space: for each node, run a second pointer through the rest of the list, O(n^2).
2. **Remove all nodes that have duplicates (LeetCode #82):** `1 -> 1 -> 2` becomes `2`. The head can change, so use a **dummy node** before the head.
3. **Memory:** in C++ you would `delete` the skipped nodes. In Dart, Java, or Python the garbage collector frees them.

## What to remember

Deleting from a linked list is re-pointing an arrow. With sorted input, duplicates are adjacent, so one forward pass with O(1) space is enough.
