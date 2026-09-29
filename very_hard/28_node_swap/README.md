# Node Swap

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Pairwise relinking with a dummy head

## The problem

Swap **every pair** of adjacent nodes in a singly linked list and return the new head. Swap the **nodes** (relink them), not their values. If the length is odd, the last node stays where it is.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5   =>   1 -> 0 -> 3 -> 2 -> 5 -> 4
0 -> 1 -> 2                  =>   1 -> 0 -> 2
```

## Step 1: Swapping one pair

Take a pair `(first, second)` with `prev` the node before it:

```
before:  prev -> first -> second -> rest
after:   prev -> second -> first -> rest
```

Three pointers change:

1. `first.next = second.next` (first now points to the rest),
2. `second.next = first`,
3. `prev.next = second`.

The order matters: step 1 must read `second.next` before step 2 overwrites it.

## Step 2: The head changes

For the first pair, there is no `prev`, and the new head is the old second node. A **dummy** node placed before the head removes this special case: `prev` starts at the dummy, and the answer is `dummy.next`.

## Step 3: Move to the next pair

After swapping, `first` is the second node of the pair, so it is the `prev` for the next pair: `prev = first`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`node_swap.dart`](node_swap.dart) (run it with `dart run`).

```dart
// Node Swap: swap every pair of adjacent nodes (by relinking, not by swapping values).
// Iterative with a dummy head. O(n) time, O(1) space.

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

LinkedList nodeSwap(LinkedList head) {
  final dummy = LinkedList(0, head);
  var prev = dummy;
  while (prev.next != null && prev.next!.next != null) {
    final first = prev.next!, second = prev.next!.next!;
    first.next = second.next;
    second.next = first;
    prev.next = second;
    prev = first; // first is now the second node of the swapped pair
  }
  return dummy.next!;
}
```

<!-- CODE:END -->

### Walkthrough

- `final dummy = LinkedList(0, head);` puts the dummy in front.
- The loop runs while a full pair exists after `prev`.
- The three pointer updates are in the order from Step 1.
- `prev = first;` moves to the next pair.

## Step 5: Dry run: `0 -> 1 -> 2 -> 3`

| prev | pair | after the swap |
|---|---|---|
| dummy | (0, 1) | dummy -> 1 -> 0 -> 2 -> 3 |
| 0 | (2, 3) | dummy -> 1 -> 0 -> 3 -> 2 |
| 2 | no full pair | stop |

Return `1 -> 0 -> 3 -> 2`.

## Recursive version

```
swap(head):
    if head or head.next is null: return head
    second = head.next
    head.next = swap(second.next)
    second.next = head
    return second
```

Shorter, but O(n) stack space.

## Complexity

- **Time: O(n)**.
- **Space: O(1)** iterative.

## Common mistakes

- Updating `second.next` before reading it.
- Forgetting the dummy (special code for the first pair, often buggy).
- Swapping values when the interviewer asked to swap nodes (always ask).

## Follow-ups

1. **Swap Nodes in Pairs (LeetCode #24).**
2. **Reverse Nodes in k-Group (#25):** the generalization: reverse each block of k nodes, with the same `prev` / block-start / block-end bookkeeping.

## What to remember

Draw the three pointer changes for one pair, order them so nothing is overwritten before it is read, and use a dummy head when the head can change.
