# Merge Linked Lists

**Difficulty:** Hard (on AlgoExpert; Easy on LeetCode) | **Category:** Linked Lists | **Pattern:** Merge step with a dummy head

## Problem
Given the heads of two sorted singly linked lists, merge them in place into one sorted list (reuse the existing nodes) and return its head.

## Building up the logic
1. This is the merge step of merge sort applied to linked lists.
2. A **dummy** node before the result removes the "which list provides the head?" special case.
3. Repeatedly attach the smaller front node to the tail and advance that list.
4. When one list runs out, attach the rest of the other in O(1). No need to walk it.
5. Using `<=` keeps the merge stable (equal values from the first list come first).

## Complexity
- Time: O(n + m).
- Space: O(1) iterative (a recursive version uses O(n + m) stack).

## Interview notes
- LeetCode #21. Follow-up #23 (Merge k Sorted Lists): min-heap of list heads, O(N log k); or pairwise divide-and-conquer merging, also O(N log k). See Merge Sorted Arrays in the very hard section.
- Merge sort on a linked list (#148) uses this plus fast/slow pointers to split: O(n log n) time, O(log n) stack, no random access needed.
