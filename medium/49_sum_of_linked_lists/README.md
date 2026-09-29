# Sum of Linked Lists

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Digit-by-digit addition with carry

## The problem

Two non-negative integers are stored as singly linked lists of digits, in **reverse order** (the head is the ones digit). Return a **new** linked list representing their sum, in the same format. Do not modify the inputs.

```
2 -> 4 -> 7 -> 1   (1742)
9 -> 4 -> 5        (549)
=>  1 -> 9 -> 2 -> 2   (2291)
```

## Step 1: Why not convert to integers?

`1742 + 549` is easy, but lists can be arbitrarily long (hundreds of digits), far beyond 64-bit integers. The robust solution works digit by digit, exactly like addition on paper.

## Step 2: Paper addition, and why reverse order helps

On paper you add from the ones digit, carrying 1 when a column exceeds 9. Here the ones digits are at the heads of the lists, so walking forward is walking from the least significant digit: exactly the order we need.

```
   2  4  7  1
 + 9  4  5
 ------------
   1  9  2  2     (2+9 = 11: write 1 carry 1; 4+4+1 = 9; 7+5 = 12: write 2 carry 1; 1+0+1 = 2)
```

## Step 3: The loop condition

Keep going while **either** list still has digits **or** there is a carry left:

```
while a != null or b != null or carry != 0
```

That single condition handles lists of different lengths (missing digits count as 0) and a final carry (`99 + 1 = 100` needs a new node for the leading 1).

A **dummy head** node lets you append every result digit the same way; return `dummy.next` at the end.

## Step 4: The code

<!-- CODE:START -->

Full source: [`sum_of_linked_lists.dart`](sum_of_linked_lists.dart) (run it with `dart run`).

```dart
// Sum of Linked Lists: numbers stored least-significant digit first. Add with carry.
// O(max(n, m)) time, O(max(n, m)) space for the result.

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

LinkedList sumOfLinkedLists(LinkedList linkedListOne, LinkedList linkedListTwo) {
  final dummy = LinkedList(0);
  var tail = dummy;
  LinkedList? a = linkedListOne, b = linkedListTwo;
  var carry = 0;
  while (a != null || b != null || carry != 0) {
    final sum = (a?.value ?? 0) + (b?.value ?? 0) + carry;
    tail.next = LinkedList(sum % 10);
    tail = tail.next!;
    carry = sum ~/ 10;
    a = a?.next;
    b = b?.next;
  }
  return dummy.next!;
}
```

<!-- CODE:END -->

### Walkthrough

- `final dummy = LinkedList(0); var tail = dummy;` is the result builder.
- `(a?.value ?? 0)` reads a digit or 0 if that list has ended.
- `tail.next = LinkedList(sum % 10);` appends the digit; `carry = sum ~/ 10`.
- `a = a?.next; b = b?.next;` advances each list if it has not ended.

## Step 5: Dry run

| a digit | b digit | carry in | sum | digit written | carry out |
|---|---|---|---|---|---|
| 2 | 9 | 0 | 11 | 1 | 1 |
| 4 | 4 | 1 | 9 | 9 | 0 |
| 7 | 5 | 0 | 12 | 2 | 1 |
| 1 | (0) | 1 | 2 | 2 | 0 |

Result: `1 -> 9 -> 2 -> 2`.

## Complexity

- **Time: O(max(n, m))**.
- **Space: O(max(n, m))** for the new list (required by the output).

## Common mistakes

- Forgetting the final carry.
- Stopping when the shorter list ends.
- Modifying the input lists when the problem asks for a new list.

## Follow-ups

1. **Add Two Numbers (LeetCode #2):** identical.
2. **Add Two Numbers II (#445):** digits stored most significant first. Options: reverse both lists, add, reverse the result; or push digits onto two stacks and build the result by prepending nodes.
3. **Multiply two numbers stored as lists:** grade-school multiplication with an array of partial sums.

## What to remember

Arbitrary-precision arithmetic is digit-by-digit with a carry. Loop while any input or the carry remains.
