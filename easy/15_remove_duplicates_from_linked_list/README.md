# Remove Duplicates From Linked List

**Difficulty:** Easy | **Category:** Linked Lists | **Pattern:** Pointer skipping

## Problem
Given the head of a singly linked list whose values are sorted ascending, remove nodes so that each value appears once. Modify the list in place and return its head.

```
1 -> 1 -> 3 -> 4 -> 4 -> 4 -> 5 -> 6 -> 6   =>   1 -> 3 -> 4 -> 5 -> 6
```

## Building up the logic
1. Sorted means duplicates are adjacent. You never need a hash set.
2. From each node, find the next node with a **different** value, then link directly to it. The skipped nodes become unreachable.
3. Then jump to that distinct node and repeat.
4. The head never changes (the first occurrence of each value is kept), so no dummy node is needed.

## Complexity
- Time: O(n), each node is visited once across both loops.
- Space: O(1).

## Edge cases
- All values equal.
- Duplicates at the tail: `nextDistinct` becomes null and terminates the list correctly.

## Interview notes
- Unsorted follow-up: use a hash set of seen values, O(n) time and O(n) space, or O(n^2) time and O(1) space with a runner pointer.
- Harder follow-up (LeetCode #82): remove **all** nodes that have duplicates. The head may change, so use a dummy/sentinel node.
- In garbage-collected languages the skipped nodes are freed automatically; in C++ mention deleting them.
