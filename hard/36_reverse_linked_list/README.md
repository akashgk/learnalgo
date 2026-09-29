# Reverse Linked List

**Difficulty:** Hard (on AlgoExpert; Easy on LeetCode) | **Category:** Linked Lists | **Pattern:** Pointer reversal

## Problem
Reverse a singly linked list in place and return the new head.

## Building up the logic
1. Walk the list once and flip each `next` pointer to point backward.
2. You need three references: `prev` (already reversed part), `current`, and `next` (saved **before** overwriting `current.next`, or you lose the rest of the list).
3. When `current` becomes null, `prev` is the new head.
4. Recursive version: reverse everything after the head, then make the old second node point back to the head and cut the head's link. Elegant, but O(n) stack.

## Complexity
- Time: O(n).
- Space: O(1) iterative, O(n) recursive.

## Interview notes
- This is a building block you must be able to write in 60 seconds without bugs: Linked List Palindrome, Reorder List / Zip Linked List, Reverse Nodes in k-Group (#25), Reverse Linked List II (#92, reverse a sublist).
- Draw the three pointers for a 3-node list and step through it before writing code.
