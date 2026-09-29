# Linked List Construction

**Difficulty:** Medium | **Category:** Linked Lists | **Pattern:** Doubly linked list pointer surgery

## Problem
Implement a doubly linked list class with `head` and `tail`, supporting:
`setHead(node)`, `setTail(node)`, `insertBefore(node, nodeToInsert)`, `insertAfter(node, nodeToInsert)`, `insertAtPosition(position, nodeToInsert)` (1-based), `removeNodesWithValue(value)`, `remove(node)`, `containsNodeWithValue(value)`.
If a node being inserted is already in the list, it is **moved** (removed first, then inserted).

## Building up the logic
1. Build everything on two primitives: `remove(node)` and `insertBefore`/`insertAfter`. `setHead` is `insertBefore(head)`, `setTail` is `insertAfter(tail)`, and `insertAtPosition` walks and then calls `insertBefore`.
2. **Remove** must handle: updating `head` if the node is the head, `tail` if it is the tail, relinking neighbors (null-safe), and clearing the node's own pointers so it can be reinserted cleanly.
3. **insertBefore:** remove first (handles "move"), then set the new node's pointers, then fix the neighbor that used to point to `node` (or `head` if there was none), then `node.prev`. Write the pointer updates in this order so you never read a pointer you already overwrote.
4. Edge case: inserting the list's only node relative to itself; return early.
5. `removeNodesWithValue`: save `next` before calling `remove`, since `remove` clears the pointers.

## Complexity
| Operation | Time |
|---|---|
| setHead, setTail, insertBefore, insertAfter, remove | O(1) |
| insertAtPosition | O(p) |
| removeNodesWithValue, containsNodeWithValue | O(n) |

Space: O(1) per operation.

## Interview notes
- Draw boxes and arrows before writing any code; say each pointer update out loud. That is what interviewers expect for pointer problems.
- A doubly linked list plus a hash map is the core of LRU Cache (very hard section).
- Sentinel (dummy) head and tail nodes eliminate most null checks; mention it as an alternative design.
