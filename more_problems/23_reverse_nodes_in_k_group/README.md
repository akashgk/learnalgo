# Reverse Nodes in k-Group

**Difficulty:** Hard | **Category:** Linked lists | **Pattern:** In-place reversal of sublists with a dummy head | **Source:** LeetCode 25; Striver A2Z, NeetCode 150

## The problem

Reverse the nodes of a linked list `k` at a time. If the number of remaining nodes is less than `k`, leave them as they are. Change links, not values. O(1) extra space.

```
1 2 3 4 5, k = 2  ->  2 1 4 3 5
1 2 3 4 5, k = 3  ->  3 2 1 4 5
```

## Step 1: Break it into known pieces

This combines three things you already know:

1. **Reverse a linked list** (AlgoExpert hard 36): `prev`, `cur`, `next` pointers.
2. **Check that k nodes exist** before reversing (the last partial group stays as is).
3. **Reconnect** each reversed group to the part before and after it.

Step 3 is where the bugs are. Draw it:

```
groupPrev -> [a -> b -> c] -> groupNext        (k = 3)
groupPrev -> [c -> b -> a] -> groupNext        after
```

After reversal, the group's **old first** node `a` becomes its **last** node and must point to `groupNext`; `groupPrev` must point to the old **last** node `c` (the k-th node). Then `a` becomes the `groupPrev` for the next group.

## Step 2: Simplify the reconnect

A neat trick: start the reversal with `prev = groupNext` instead of `prev = null`. The first node reversed (`a`) then points to `groupNext` automatically. After the loop, only `groupPrev.next = kth` remains.

A **dummy node** in front of the head means the first group has a `groupPrev` too, so the head needs no special case. Return `dummy.next`.

## Step 3: Recursive alternative

Reverse the first k nodes, then set the old first node's `next` to `reverseKGroup(rest, k)`. Very readable, but O(n/k) recursion depth, so not O(1) space. Mention it; implement the iterative one.

## Step 4: The code

<!-- CODE:START -->

Full source: [`reverse_nodes_in_k_group.dart`](reverse_nodes_in_k_group.dart) (run it with `dart run`).

```dart
// Reverse Nodes in k-Group: reverse every consecutive block of k nodes; a final block
// shorter than k stays as is. Iterative, relinking in place. O(n) time, O(1) space.

class ListNode {
  ListNode(this.value, [this.next]);
  int value;
  ListNode? next;
}

ListNode? reverseKGroup(ListNode? head, int k) {
  final dummy = ListNode(0, head);
  var groupPrev = dummy; // node just before the current group
  while (true) {
    // Find the k-th node of this group; stop if the group is incomplete.
    ListNode? kth = groupPrev;
    for (var i = 0; i < k && kth != null; i++) {
      kth = kth.next;
    }
    if (kth == null) break;
    final groupNext = kth.next; // first node after the group
    // Standard reversal, but the reversed tail links to groupNext instead of null.
    ListNode? prev = groupNext;
    var cur = groupPrev.next;
    while (cur != groupNext) {
      final next = cur!.next;
      cur.next = prev;
      prev = cur;
      cur = next;
    }
    // The old first node is now the last node of the group.
    final oldFirst = groupPrev.next!;
    groupPrev.next = kth;
    groupPrev = oldFirst;
  }
  return dummy.next;
}

ListNode? fromList(List<int> values) {
  ListNode? head;
  for (final v in values.reversed) {
    head = ListNode(v, head);
  }
  return head;
}

List<int> toList(ListNode? head) => [for (var c = head; c != null; c = c.next) c.value];
```

<!-- CODE:END -->

### Walkthrough

- The `for` loop walks k steps from `groupPrev`; if it falls off the list, fewer than k nodes remain and we stop, leaving them untouched.
- `groupNext = kth.next` is saved before any link changes.
- The reversal loop runs until `cur` reaches `groupNext`, so it reverses exactly the k group nodes.
- `oldFirst` is read **before** `groupPrev.next` is overwritten. After the reversal it is the group's tail, and it becomes the next `groupPrev`.

## Step 5: Dry run

`1 2 3 4 5`, k = 2. `D` is the dummy.

| Group | Before | kth | After reconnect | next groupPrev |
|---|---|---|---|---|
| 1 | D -> 1 -> 2 -> 3 -> 4 -> 5 | 2 | D -> 2 -> 1 -> 3 -> 4 -> 5 | 1 |
| 2 | ... 1 -> 3 -> 4 -> 5 | 4 | D -> 2 -> 1 -> 4 -> 3 -> 5 | 3 |
| 3 | ... 3 -> 5 | walking 2 steps falls off | stop | |

Result: `2 1 4 3 5`.

## Complexity

- Time: **O(n)**. Each node is visited a constant number of times (once to count, once to reverse).
- Space: **O(1)**.

## Edge cases

- `k = 1`: every group is one node; nothing changes.
- `k` larger than the length: nothing changes.
- Length a multiple of k: the last group is reversed too.
- Empty list.

## Common mistakes

- Reversing the last partial group.
- Losing `groupNext` or `oldFirst` by overwriting pointers before saving them.
- Not advancing `groupPrev` to the old first node (the second group reconnects to the wrong place).

## Follow-ups you should be ready for

1. **Reverse Linked List II (LeetCode 92).** Reverse only positions `left..right`: exactly one iteration of this loop.
2. **Swap Nodes in Pairs (LeetCode 24).** This problem with k = 2; see AlgoExpert very_hard 28 Node Swap.
3. **Reverse the last partial group too.** Drop the length check and reverse whatever remains.

## What to remember

Save the boundary nodes (`groupPrev`, `groupNext`, old first, k-th) before touching links, use a dummy head, and start the reversal with `prev = groupNext` so the tail reconnects itself.
