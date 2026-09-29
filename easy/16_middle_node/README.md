# Middle Node

**Difficulty:** Easy | **Category:** Linked Lists | **Pattern:** Fast and slow pointers

## Problem
Given the head of a non-empty singly linked list, return its middle node. If there are two middle nodes (even length), return the second one.

## Building up the logic
1. Two-pass: count the length, then walk `length ~/ 2` steps. O(n) time, O(1) space. Perfectly acceptable; say it first.
2. One-pass: if one pointer moves twice as fast as another, when the fast one reaches the end the slow one has covered half the distance.
3. Loop condition `fast != null && fast.next != null` handles both parities. Trace it on lengths 1, 2, 3, 4 before claiming it works: for length 4 (`a b c d`), slow ends at `c` (second middle).
4. If the interviewer wants the **first** middle for even lengths, start `fast` at `head.next`.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- Fast/slow pointers are a core linked-list tool. Same idea: cycle detection (Find Loop), palindrome check (find middle, reverse second half), and reorder list.
- LeetCode #876.
