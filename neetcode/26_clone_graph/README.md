# Clone Graph

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** DFS/BFS with an original -> copy map | **Source:** LeetCode 133; NeetCode 150, Blind 75

## The problem

Given a node of a connected undirected graph (each node has a value and a list of neighbors), return a **deep copy** of the graph.

```
1 -- 2
|    |
4 -- 3
```

The copy has four new nodes connected the same way, sharing no node objects with the original.

## Step 1: The two difficulties

1. **Cycles.** Following neighbors naively loops forever (1 -> 2 -> 1 -> ...).
2. **Shared nodes.** Node 3 is reachable from both 2 and 4. The copy must have **one** node 3 that both copies of 2 and 4 point to, not two separate copies.

Both are solved by one structure: a map from each original node to its copy. It is the visited set (stops cycles) and the lookup "which copy belongs to this original?" (keeps sharing correct). This is the same idea as more_problems 22 Copy List with Random Pointer.

## Step 2: DFS

```
clone(original):
  if original is in the map: return its copy
  copy = new node(original.value)
  map[original] = copy            // BEFORE visiting neighbors
  for each neighbor n: copy.neighbors.add(clone(n))
  return copy
```

Registering the copy **before** recursing is essential. With a cycle 1 -> 2 -> 1, the call for 2 asks for clone(1), which must find the half-built copy of 1 instead of starting over.

## Step 3: The code

<!-- CODE:START -->

Full source: [`clone_graph.dart`](clone_graph.dart) (run it with `dart run`).

```dart
// Clone Graph: deep-copy a connected undirected graph given one node.
// DFS with a map original -> copy. The map doubles as the visited set and breaks cycles.
// O(V + E) time, O(V) space.

class Node {
  Node(this.value);
  int value;
  final neighbors = <Node>[];
}

Node? cloneGraph(Node? node) {
  if (node == null) return null;
  final copies = <Node, Node>{};
  Node clone(Node original) {
    final existing = copies[original];
    if (existing != null) return existing;
    final copy = Node(original.value);
    copies[original] = copy; // register BEFORE recursing, or a cycle recurses forever
    for (final n in original.neighbors) {
      copy.neighbors.add(clone(n));
    }
    return copy;
  }

  return clone(node);
}

/// Builds a graph from an adjacency list (1-indexed values, like LeetCode) and returns node 1.
Node? build(List<List<int>> adj) {
  if (adj.isEmpty) return null;
  final nodes = [for (var i = 1; i <= adj.length; i++) Node(i)];
  for (var i = 0; i < adj.length; i++) {
    for (final j in adj[i]) {
      nodes[i].neighbors.add(nodes[j - 1]);
    }
  }
  return nodes[0];
}

/// Adjacency list reachable from [start], ordered by value, for comparison.
List<List<int>> encode(Node? start) {
  if (start == null) return [];
  final seen = <Node>{};
  final stack = [start];
  while (stack.isNotEmpty) {
    final n = stack.removeLast();
    if (seen.add(n)) stack.addAll(n.neighbors);
  }
  final sorted = seen.toList()..sort((a, b) => a.value.compareTo(b.value));
  return [
    for (final n in sorted) [for (final m in n.neighbors) m.value],
  ];
}
```

<!-- CODE:END -->

### Walkthrough

- `copies` maps original to copy.
- `copies[original] = copy` happens before the neighbor loop.
- `build` and `encode` exist only for the tests: `encode` records the adjacency list reachable from a node, so the copy can be compared with the original.

## Step 4: Dry run

Square graph, starting at 1:

| call | map before | action |
|---|---|---|
| clone(1) | {} | create 1', map {1} ; visit 2 |
| clone(2) | {1} | create 2'; visit 1: already mapped, return 1'; visit 3 |
| clone(3) | {1, 2} | create 3'; visit 2 (mapped), visit 4 |
| clone(4) | {1, 2, 3} | create 4'; visit 1 (mapped), 3 (mapped) |
| back in clone(1) | all | visit 4: mapped, return 4' |

Every copy gets exactly the neighbors of its original, pointing to copies.

## Complexity

- Time: **O(V + E)**.
- Space: **O(V)** for the map, plus O(V) recursion depth in the worst case (use BFS to avoid deep recursion).

## Edge cases

- Null input: null.
- Single node with no neighbors.
- Self loops: the map returns the copy itself.

## Common mistakes

- Registering the copy after visiting neighbors (infinite recursion on cycles).
- Using a visited set of **values** when values are not unique.
- Copying neighbors lists by reference (`copy.neighbors = original.neighbors`): a shallow copy.

## Follow-ups you should be ready for

1. **BFS version.** Queue of originals; create copies when first seen, then add edges while processing.
2. **Directed graphs, disconnected graphs.** Same map; for a disconnected graph, start from every node.
3. **Clone a graph with extra pointers (random pointers, parent pointers).** Same map idea.

## What to remember

Deep-copying any pointer structure: keep a map from original to copy, and register each copy before following its links.
