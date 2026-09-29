# Sort Stack

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Recursion as an implicit second stack

## The problem

Given a stack of integers (a list whose **end** is the top), sort it so that the **largest** value is on top. You may only use stack operations (push, pop, peek, isEmpty) and recursion. No other data structures.

```
[-5, 2, -2, 4, 3, 1]  ->  [-5, -2, 1, 2, 3, 4]    (4 on top)
```

## Step 1: Think insertion sort

Insertion sort: if the rest of the collection is already sorted, you only need to **insert one element** in the right place.

For a stack:

1. Pop the top element `t`.
2. Recursively sort the remaining stack (trust that it works: "recursive leap of faith").
3. Insert `t` into the sorted stack at the right position.

## Step 2: Inserting into a sorted stack

```
insert(stack, value):
    if stack is empty or top <= value:
        push value; return
    top = pop()
    insert(stack, value)     # value goes somewhere below
    push top                 # restore the bigger element on top
```

The recursion's call stack temporarily holds the popped elements. That is the "second stack" the rules forbid you from creating explicitly.

## Step 3: The code

<!-- CODE:START -->

Full source: [`sort_stack.dart`](sort_stack.dart) (run it with `dart run`).

```dart
// Sort Stack using only push/pop/peek/isEmpty and recursion (no extra data structures).
// Pop everything, then insert each value back into its sorted position recursively.
// O(n^2) time, O(n) recursion space. The top of the stack ends up as the largest value.

List<int> sortStack(List<int> stack) {
  if (stack.isEmpty) return stack;
  final top = stack.removeLast();
  sortStack(stack);
  _insertInSortedOrder(stack, top);
  return stack;
}

void _insertInSortedOrder(List<int> stack, int value) {
  if (stack.isEmpty || stack.last <= value) {
    stack.add(value);
    return;
  }
  final top = stack.removeLast();
  _insertInSortedOrder(stack, value);
  stack.add(top);
}
```

<!-- CODE:END -->

### Walkthrough

- `sortStack`: base case empty stack; otherwise pop, sort the rest, insert the popped value.
- `_insertInSortedOrder`: push if it belongs on top; otherwise temporarily remove the top, insert deeper, then put the top back.

## Step 4: Dry run (small example `[3, 1, 2]`, top is 2)

| call | action | stack |
|---|---|---|
| sort([3,1,2]) | pop 2, sort [3,1] | [3, 1] |
| sort([3,1]) | pop 1, sort [3] | [3] |
| sort([3]) | pop 3, sort [], insert 3 | [3] |
| insert 1 into [3] | 3 > 1: pop 3, insert 1 into [], push 3 | [1, 3] |
| insert 2 into [1,3] | 3 > 2: pop 3; insert 2 into [1]: 1 <= 2, push; push 3 | [1, 2, 3] |

## Complexity

- **Time: O(n^2)**: each of n insertions may pass through the whole stack.
- **Space: O(n)** recursion depth (two nested recursions, each at most n deep).

## Iterative version with one extra stack

If an auxiliary stack is allowed (Cracking the Coding Interview problem 3.5): pop from the input into `temp`; while `temp`'s top is bigger than the popped value, move it back to the input; then push the value onto `temp`. `temp` stays sorted. Also O(n^2).

## Common mistakes

- Forgetting to push the popped top back after inserting deeper.
- Getting the direction reversed (smallest on top).

## What to remember

When extra data structures are banned but recursion is allowed, the call stack is your extra stack. Structure the solution as "sort the rest, insert one".
