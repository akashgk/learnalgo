# Merging Linked Lists

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Two pointers that equalize path lengths

## Problem
Two singly linked lists may merge at some node, after which they share all remaining nodes. Return the first shared node, or null if they never merge. Do not modify the lists.

## Building up the logic
1. Hash set: store every node of list one, walk list two, return the first node in the set. O(n + m) time, O(n) space.
2. Length difference: compute both lengths, advance the longer list's pointer by the difference, then walk together until the pointers are identical. O(n + m), O(1).
3. **Elegant version:** pointer `a` walks list one then list two; pointer `b` walks list two then list one. Both travel `lenA + lenB` nodes in total, so they reach the intersection at the same step. With no intersection, both become null at the same time and the loop ends.
4. Compare node **identity**, not values. Two different nodes can hold equal values.

## Complexity
- Time: O(n + m).
- Space: O(1).

## Interview notes
- LeetCode #160. Explain why the switch-heads version terminates: after at most `n + m` steps both pointers are either at the same node or both null.
