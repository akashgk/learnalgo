# Breadth-first Search

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** BFS with a queue

## The problem

Implement `breadthFirstSearch` on a `Node` class (name + list of children, acyclic). Starting from the node it is called on, visit nodes **level by level** (all nodes at distance 1, then distance 2, ...), children in left-to-right order, and return the names in visit order.

```
            A
         /  |  \
        B   C   D
       / \     / \
      E   F   G   H
         / \   \
        I   J   K

-> [A, B, C, D, E, F, G, H, I, J, K]
```

## Step 1: Work an example by hand

Level 0: A. Level 1: A's children B, C, D. Level 2: B's children E, F, then D's children G, H. Level 3: F's children I, J, then G's child K.

To do this mechanically you need a **waiting line**: when you visit a node, its children join the **back** of the line, and you always take the next node from the **front**. First in, first out: a queue.

Compare with DFS, which uses a stack (last in, first out) and dives down B's whole subtree before visiting C.

## Step 2: The algorithm

```
queue = [start]
while queue not empty:
    node = queue.removeFirst()
    record node.name
    queue.addAll(node.children)
```

Why does this produce level order? All level-k nodes enter the queue before any level-(k+1) node, because level-(k+1) nodes are added only while level-k nodes are being processed. FIFO order preserves that.

## Step 3: The code

<!-- CODE:START -->

Full source: [`breadth_first_search.dart`](breadth_first_search.dart) (run it with `dart run`).

```dart
// Breadth-first Search on a tree-like graph: return names in level order.
// O(v + e) time, O(v) space.

import 'dart:collection';

class Node {
  Node(this.name, [List<Node>? children]) : children = children ?? [];
  final String name;
  final List<Node> children;

  List<String> breadthFirstSearch() {
    final out = <String>[];
    final queue = Queue<Node>()..add(this);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      out.add(node.name);
      queue.addAll(node.children);
    }
    return out;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `Queue<Node>()..add(this)` from `dart:collection` provides O(1) `removeFirst`.
- `out.add(node.name);` records the visit.
- `queue.addAll(node.children);` enqueues children in order.

## Step 4: Dry run

| dequeued | queue after enqueuing children |
|---|---|
| A | B, C, D |
| B | C, D, E, F |
| C | D, E, F |
| D | E, F, G, H |
| E | F, G, H |
| F | G, H, I, J |
| G | H, I, J, K |
| H, I, J, K | (empty) |

Output: `A, B, C, D, E, F, G, H, I, J, K`.

## Complexity

- **Time: O(v + e)**: each vertex is enqueued and dequeued once; each edge is followed once.
- **Space: O(v)**: the queue can hold a whole level (up to about v/2 nodes in a wide tree) plus the output.

## Critical implementation details

1. **Use a real queue.** `List.removeAt(0)` shifts every element: O(n) per dequeue, turning BFS into O(v^2). Same trap as `list.pop(0)` in Python (use `collections.deque`) and `ArrayList.remove(0)` in Java (use `ArrayDeque`).
2. **On general graphs, mark nodes visited when you ENQUEUE them**, not when you dequeue them. Otherwise a node reachable from several nodes of the same level is enqueued several times.

## Level-by-level processing

Many problems need to know where each level ends (right side view, level averages, zigzag order, minimum depth). Idiom: at the start of each level, record `size = queue.length` and process exactly that many nodes before moving on. Minimum Passes Of Matrix (medium 42) uses the equivalent "swap in a new queue per level".

## BFS vs DFS

| | BFS | DFS |
|---|---|---|
| Structure | queue | stack / recursion |
| Memory | O(width) | O(depth) |
| Gives | shortest paths in **unweighted** graphs | any path; natural for backtracking, topological sort, cycle detection |

For weighted shortest paths use Dijkstra (hard 26); for 0/1 weights, a deque-based "0-1 BFS".

## What to remember

BFS = queue = level order = shortest paths in unweighted graphs. Use an O(1) queue and mark visited on enqueue.
