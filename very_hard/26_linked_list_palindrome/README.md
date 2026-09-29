# Linked List Palindrome

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Middle + reverse second half

## Problem
Return whether the values of a singly linked list read the same forwards and backwards. Target O(1) extra space.

## Building up the logic
1. Copy values to an array and use two pointers: O(n) space. Or push the first half onto a stack: still O(n).
2. A singly linked list can only be read forward. To compare the first half with the second half **backwards**, reverse the second half in place.
3. Steps:
   - find the middle with fast/slow pointers (Middle Node);
   - reverse from the middle to the end (Reverse Linked List);
   - walk both halves together comparing values;
   - reverse the second half back to restore the input (good practice; say so).
4. Odd lengths need no special case: the middle node becomes the last node of the reversed half, and the first half still links to it, so the final comparison is the middle node against itself.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #234. The combination "find middle + reverse + compare/merge" also solves Zip Linked List (#143 Reorder List). Master these three primitives and several "very hard" linked-list problems become routine.
- A recursive O(n)-stack solution also exists (a front pointer advanced as recursion unwinds); it is elegant but not O(1) space.
