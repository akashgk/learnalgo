# Sum of Linked Lists

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Digit-by-digit addition with carry

## Problem
Two non-negative integers are stored as singly linked lists of digits in **reverse** order (least significant digit first). Return a new linked list representing their sum in the same format. The input lists must not be modified.

```
2 -> 4 -> 7 -> 1  (1742)
9 -> 4 -> 5       (549)
=> 1 -> 9 -> 2 -> 2  (2291)
```

## Building up the logic
1. Converting to integers and back fails for long lists (overflow). Do it digit by digit, exactly like grade-school addition.
2. Reverse order is convenient: the head is the ones digit, so you add from the head.
3. Loop while **either** list has digits **or** a carry remains. That single condition handles unequal lengths and the final carry (99 + 1).
4. A dummy head node avoids special-casing the first result node.

## Complexity
- Time: O(max(n, m)).
- Space: O(max(n, m)) for the result.

## Interview notes
- LeetCode #2 (Add Two Numbers). Follow-up #445: digits stored most-significant first. Either reverse both lists, or push digits onto two stacks and build the result by prepending.
