# Sort Stack

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Recursion as an implicit second stack

## Problem
Sort a stack (represented as a list whose end is the top) so the largest value is on top. You may only use stack operations (push, pop, peek, isEmpty) and recursion; no other data structures.

## Building up the logic
1. Think of it like insertion sort. If the rest of the stack is already sorted, you only need to insert one value in the right place.
2. `sortStack`: pop the top, sort the remainder recursively, then insert the popped value.
3. `insertInSortedOrder(value)`: if the stack is empty or its top is `<=` value, push. Otherwise pop the top, insert recursively, push the top back.
4. The recursion stack is doing the work of the auxiliary structure; you are allowed it because the problem permits recursion.

## Complexity
- Time: O(n^2): each of n insertions may pass through the whole stack.
- Space: O(n) recursion depth.

## Interview notes
- Iterative version with one extra stack (Cracking the Coding Interview 3.5): pop from the input, move larger elements from the temp stack back to the input until the popped value fits, push it. Also O(n^2).
- This question tests recursion fluency more than algorithms; narrate the "assume the recursive call works" leap of faith.
