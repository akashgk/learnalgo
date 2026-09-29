# Linked List Palindrome

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Find the middle + reverse the second half

## The problem

Return whether the values of a singly linked list read the same forward and backward. Target **O(1) extra space**.

```
0 -> 1 -> 2 -> 2 -> 1 -> 0   ->  true
1 -> 2 -> 3 -> 2 -> 1        ->  true
1 -> 2                       ->  false
```

## Step 1: Easy versions with extra space

- Copy values into an array and compare with two pointers: O(n) space.
- Push the first half onto a stack, then compare while popping: O(n) space.

## Step 2: The obstacle

A palindrome check compares the first element with the last, the second with the second-to-last, and so on. A singly linked list can only be walked **forward**, so we cannot walk the second half backward.

**Fix:** make the second half point backward by **reversing it in place**.

## Step 3: The algorithm (three building blocks)

1. **Find the middle** with slow and fast pointers (Middle Node, easy 16).
2. **Reverse** the list from the middle to the end (Reverse Linked List, hard 36).
3. **Compare** the first half and the reversed second half node by node.
4. **Restore** the list by reversing the second half again. The caller should not find their list modified; saying this out loud is good practice.

Odd lengths need no special case: the middle node ends up as the last node of the reversed half, and the first half still links to it, so the final comparison is the middle node against itself.

## Step 4: The code

<!-- CODE:START -->

Full source: [`linked_list_palindrome.dart`](linked_list_palindrome.dart) (run it with `dart run`).

```dart
// Linked List Palindrome: find the middle, reverse the second half, compare, restore.
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

bool linkedListPalindrome(LinkedList head) {
  // Slow ends at the start of the second half (the middle node for odd lengths).
  var slow = head;
  LinkedList? fast = head;
  while (fast != null && fast.next != null) {
    slow = slow.next!;
    fast = fast.next!.next;
  }
  final secondHead = _reverse(slow);
  var isPalindrome = true;
  LinkedList? a = head, b = secondHead;
  while (b != null) {
    if (a!.value != b.value) {
      isPalindrome = false;
      break;
    }
    a = a.next;
    b = b.next;
  }
  _reverse(secondHead); // restore the original list for the caller
  return isPalindrome;
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

- The slow/fast loop leaves `slow` at the start of the second half (the middle for odd lengths, the second middle for even lengths).
- `_reverse(slow)` reverses the second half and returns its new head (the old tail).
- The comparison walks both halves while the reversed half has nodes.
- `_reverse(secondHead)` restores the original order before returning.

## Step 5: Dry run: `0 -> 1 -> 2 -> 2 -> 1 -> 0`

| step | state |
|---|---|
| middle | slow stops at the second `2` (index 3) |
| reverse second half | first half 0 -> 1 -> 2 -> (2), second half 0 -> 1 -> 2 |
| compare | 0 = 0, 1 = 1, 2 = 2: palindrome |
| restore | original list again |

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Forgetting to restore the list (a silent side effect).
- Off-by-one in the middle for even lengths, which misaligns the comparison.

## Alternative: recursion

A recursive function that walks to the end and compares on the way back, with a "front" pointer advanced after each comparison. Elegant, but O(n) call stack, so it does not meet the O(1) space target.

## Follow-ups

1. **Palindrome Linked List (LeetCode #234).**
2. **Reorder List (#143):** the same three building blocks (see Zip Linked List, very hard 27).

## What to remember

Many "hard" linked-list problems are three primitives combined: find the middle, reverse a list, walk two lists together.
