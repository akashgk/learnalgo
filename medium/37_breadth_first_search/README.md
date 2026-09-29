# Breadth-first Search

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** BFS with a queue

## Problem
Implement `breadthFirstSearch` on a `Node` class (name + children, acyclic). Visit nodes level by level, children left to right, and return the names in visit order.

## Building up the logic
1. BFS explores all nodes at distance d before any at distance d + 1. A FIFO **queue** enforces that: nodes discovered earlier are processed earlier.
2. Template: enqueue the start; while the queue is not empty, dequeue, record, enqueue its children.
3. On general graphs, mark nodes visited **when enqueued** (not when dequeued), otherwise a node can be enqueued many times.
4. Use a real queue. In Dart, `Queue` from `dart:collection` gives O(1) `removeFirst`. `List.removeAt(0)` is O(n) and silently turns BFS into O(n^2). Same trap as `list.pop(0)` in Python (use `collections.deque`).

## Complexity
- Time: O(v + e).
- Space: O(v) for the queue and output.

## Interview notes
- BFS gives shortest paths in **unweighted** graphs. For weighted graphs use Dijkstra (non-negative) or Bellman-Ford.
- Level-by-level processing (for "right side view", "level averages", "minimum depth") uses the `for (i < queue.length at level start)` idiom. See Minimum Passes Of Matrix for a multi-source BFS.
