# Node Swap

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Pairwise relinking with a dummy head

## Problem
Swap every pair of adjacent nodes in a singly linked list and return the new head. Swap the nodes themselves, not their values. If the length is odd, the last node stays in place.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5   =>   1 -> 0 -> 3 -> 2 -> 5 -> 4
```

## Building up the logic
1. For each pair `(first, second)` preceded by `prev`, three links change:
   - `first.next = second.next`
   - `second.next = first`
   - `prev.next = second`
2. The head changes (the second node becomes the head), so start with a **dummy** node before the head; `prev` starts at the dummy.
3. Advance `prev` to `first`, which is now the tail of the swapped pair.
4. Recursive version: `swap(head) = second` with `second.next = first` and `first.next = swap(third)`. Clean, O(n) stack.

## Complexity
- Time: O(n).
- Space: O(1) iterative, O(n) recursive.

## Interview notes
- LeetCode #24. The generalization (#25, Reverse Nodes in k-Group) reverses each block of k with the same prev/first/last bookkeeping.
- Swapping values is usually disallowed in the interview statement: always ask.
