# Zip Linked List

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Split + reverse + interleave

## Problem
Rearrange a singly linked list `1 -> 2 -> ... -> n` in place into `1 -> n -> 2 -> n-1 -> 3 -> ...` and return the head.

## Building up the logic
1. With an array of node references, two pointers from both ends make it easy: O(n) space.
2. In O(1) space, observe the output alternates between the first half in order and the second half **in reverse**.
3. Steps:
   - find the middle (slow/fast; stop so the first half keeps the extra node for odd n);
   - cut the list after the middle;
   - reverse the second half;
   - interleave the two lists node by node.
4. Save both `next` pointers before relinking during the interleave.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #143 (Reorder List). Same three primitives as Linked List Palindrome. Test with lengths 1, 2, 3, 4 to catch middle-finding off-by-ones.
