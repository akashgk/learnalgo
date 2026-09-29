# Rearrange Linked List

**Difficulty:** Very Hard | **Category:** Linked Lists | **Pattern:** Stable partition into sublists with dummy heads

## Problem
Given a singly linked list and an integer k, rearrange it in place so that all nodes with values less than k come first, then nodes equal to k, then nodes greater than k. The relative order within each group must be preserved. Return the new head.

```
3 -> 0 -> 5 -> 2 -> 1 -> 4, k = 3   =>   0 -> 2 -> 1 -> 3 -> 5 -> 4
```

## Building up the logic
1. Copying values into an array, stable-partitioning, and writing them back is O(n) space and does not move nodes.
2. Build **three separate lists** as you walk once: less, equal, greater. Appending to the tail of each list keeps original order (stable).
3. **Dummy heads** for each list avoid special cases for the first node of each group.
4. Detach each node (`node.next = null`) as you move it to prevent accidental cycles, and terminate the last list.
5. Concatenate: less -> equal -> greater, skipping empty groups. The new head is the first non-empty group's first node.

## Complexity
- Time: O(n).
- Space: O(1) (a constant number of pointers and three dummy nodes).

## Interview notes
- LeetCode #86 (Partition List) is the two-group version. Being careful about empty groups and about terminating the final tail is what separates a bug-free answer from an almost-right one.
