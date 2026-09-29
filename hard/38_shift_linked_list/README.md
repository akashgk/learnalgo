# Shift Linked List

**Difficulty:** Hard | **Category:** Linked Lists | **Pattern:** Length + modular offset + relink

## Problem
Shift a singly linked list in place by `k` positions and return the new head. Positive `k` shifts forward (the last k nodes move to the front); negative `k` shifts backward (the first |k| nodes move to the end). `k` may exceed the length.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5, k = 2   =>  4 -> 5 -> 0 -> 1 -> 2 -> 3
0 -> 1 -> 2 -> 3 -> 4 -> 5, k = -2  =>  2 -> 3 -> 4 -> 5 -> 0 -> 1
```

## Building up the logic
1. Shifting one step at a time k times is O(n * k). Shifting by `k` is the same as shifting by `k mod length`, so reduce first.
2. A backward shift by `m` equals a forward shift by `length - m`. With a non-negative modulo (Dart's `%`), `k % length` handles both signs at once. In Java/C++ compute `((k % n) + n) % n`.
3. For a forward shift by `offset`, the new tail is the node at index `length - offset - 1`, the new head is the one after it. Cut there, and link the old tail to the old head.
4. One pass to get length and tail, one partial pass to the new tail.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #61 (Rotate List) is the positive-k version. Alternative: close the list into a ring, walk to the new tail, break the ring.
