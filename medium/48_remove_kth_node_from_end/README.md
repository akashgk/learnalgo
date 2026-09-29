# Remove Kth Node From End

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Two pointers with a fixed gap

## The problem

Given the head of a singly linked list (at least two nodes) and an integer k (1 <= k <= length), remove the k-th node **from the end**, in place. The function returns nothing, so the head **object** must remain the head: if the head itself is the node to remove, overwrite it with the next node's value and link.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9, k = 4
=>  0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 7 -> 8 -> 9      (6 removed)
```

## Step 1: Two-pass solution

1. Walk once to find the length n.
2. The target is at index `n - k` (0-based). Walk to index `n - k - 1` (the node before it) and set its `next` to skip the target.

O(n) time, O(1) space. A perfectly good answer.

## Step 2: One pass: keep a gap of k

Move a `lead` pointer k nodes ahead. Then move `lead` and `trail` together, one step at a time, until `lead` is on the **last** node. The distance between them stays k, so `trail` ends exactly **one node before** the k-th node from the end. Unlink `trail.next`.

If `lead` becomes null after the first k steps, then k equals the length, and the node to remove is the head.

## Step 3: Removing the head without returning a new head

The caller keeps a reference to the head object, and the function returns nothing. So we cannot change which object is the head. Instead, copy the second node into the head (`head.value = head.next.value; head.next = head.next.next`). This effectively deletes the second node's object while the head object now represents the rest of the list.

(If the function could return the new head, a **dummy node** placed before the head would remove this special case entirely. That is the standard LeetCode #19 approach.)

## Step 4: The code

<!-- CODE:START -->

Full source: [`remove_kth_node_from_end.dart`](remove_kth_node_from_end.dart) (run it with `dart run`).

```dart
// Remove Kth Node From End (in place). Two pointers k apart.
// The head must stay the same object, so removing the head copies the next node into it.
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

void removeKthNodeFromEnd(LinkedList head, int k) {
  LinkedList? lead = head;
  for (var i = 0; i < k; i++) {
    lead = lead!.next;
  }
  if (lead == null) {
    // k == length: remove the head by copying the second node into it.
    head
      ..value = head.next!.value
      ..next = head.next!.next;
    return;
  }
  var trail = head;
  while (lead!.next != null) {
    lead = lead.next;
    trail = trail.next!;
  }
  trail.next = trail.next!.next; // trail is just before the node to delete
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop moves `lead` k steps.
- `if (lead == null)` handles "remove the head" by copying the next node into it.
- The second loop advances both until `lead.next == null` (lead on the last node).
- `trail.next = trail.next!.next;` unlinks the target.

## Step 5: Dry run (k = 4, list 0..9)

| phase | lead | trail |
|---|---|---|
| after k = 4 steps | 4 | 0 |
| move together | ... | ... |
| stop (lead on 9, the last node) | 9 | 5 |

`trail` is 5, `trail.next` is 6: remove 6.

## Complexity

- **Time: O(n)**, one pass.
- **Space: O(1)**.

## Common mistakes

- Stopping when `lead == null` instead of `lead.next == null` (then `trail` lands on the target, not before it).
- Not handling k == length.

## Follow-ups

1. **Remove Nth Node From End (LeetCode #19):** returns the head; use a dummy node.
2. **Return the k-th node from the end** instead of removing it: same gap technique.
3. **Delete a node given only a pointer to it (#237):** copy the next node's value into it and skip the next node, the same trick used here for the head.

## What to remember

A fixed gap between two pointers finds positions measured from the end in one pass. A dummy node removes head special cases when you can return a new head.
