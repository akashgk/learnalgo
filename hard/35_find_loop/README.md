# Find Loop

**Difficulty:** Hard | **Category:** Linked Lists | **Pattern:** Floyd's cycle detection

## Problem
A singly linked list contains a loop (some node's `next` points back to an earlier node). Return the node where the loop begins, using O(1) extra space.

## Building up the logic
1. Hash set of visited nodes: the first repeated node is the loop start. O(n) time, O(n) space.
2. **Detect the loop:** slow moves 1 step, fast moves 2. Once both are in the loop, fast gains one step per iteration, so they must meet.
3. **Find the start (the proof interviewers ask for):** let `D` = distance from head to loop start, `L` = loop length, and suppose they meet `P` steps into the loop. Slow walked `D + P`; fast walked `2(D + P)`. Fast's extra distance `D + P` is a whole number of loops: `D + P = kL`, so `D = kL - P`.
4. That means walking `D` steps from the meeting point lands exactly on the loop start (you complete the loop `P` short of k laps). So reset one pointer to the head and move both one step at a time; they meet at the loop start.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #142 (Linked List Cycle II). #287 (Find the Duplicate Number) is the same algorithm on an array interpreted as `i -> nums[i]`; interviewers love this connection.
- Loop length: after meeting, keep one pointer fixed and count steps until the other returns.
