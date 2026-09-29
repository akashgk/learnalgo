# Remove Kth Node From End

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Two pointers with a fixed gap

## Problem
Given the head of a singly linked list with at least two nodes and an integer k (1 <= k <= length), remove the k-th node from the end, in place. The function returns nothing, so the head object itself must remain the head: if the head is removed, overwrite it with the next node's value and link.

## Building up the logic
1. Two-pass: compute the length n, then walk to node `n - k - 1` (the one before the target) and unlink. Fine, O(n).
2. One-pass: advance a `lead` pointer k steps. Then move `lead` and `trail` together until `lead` is on the last node. The gap stays k, so `trail` stops just **before** the k-th node from the end.
3. If `lead` became null after the first k steps, then k equals the length and the head is the target.
4. Because we cannot return a new head, handle head removal by copying the second node into the head. (In the LeetCode version, #19, you return the new head; a dummy node before the head removes this special case entirely.)

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- Say "dummy node" early for any linked-list problem where the head might change. It simplifies code and interviewers like it.
