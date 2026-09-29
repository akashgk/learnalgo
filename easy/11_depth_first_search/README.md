# Depth-first Search

**Difficulty:** Easy | **Category:** Graphs | **Pattern:** DFS traversal

## The problem

You are given a `Node` class: each node has a `name` and a list of `children`. Together they form an acyclic tree-like graph. Implement `depthFirstSearch` on the class. It should traverse the graph starting from the node it is called on, going **deep before wide** (fully explore the first child before moving to the second, children in left-to-right order), and return the list of names in visit order.

```
            A
         /  |  \
        B   C   D
       / \     / \
      E   F   G   H
         / \   \
        I   J   K

-> [A, B, E, F, I, J, C, D, G, K, H]
```

### Clarifying questions

- Can the graph contain cycles? (No. With cycles you must keep a `visited` set, or DFS loops forever.)
- Order of children? (Left to right, as stored.)

## Step 1: Work an example by hand

Start at A and record it. Go to its first child B and record it. Go to B's first child E, record it. E has no children: go back to B and take its next child F. Record F, then F's children I and J. F is done, B is done: back to A, next child C. And so on.

What you are doing is: **visit me, then run the same procedure on each child, in order**. Any procedure defined in terms of itself on smaller inputs is recursion.

## Step 2: Recursive DFS

```
dfs(node):
    record node.name
    for each child in node.children:
        dfs(child)
```

The recursion's call stack remembers "where to come back to" for you. When `dfs(E)` returns, execution continues inside `dfs(B)`'s loop with the next child.

## Step 3: Iterative DFS (know this too)

Replace the call stack with an explicit stack:

```
stack = [start]
while stack not empty:
    node = stack.pop()
    record node.name
    push node.children in REVERSE order
```

Children are pushed in reverse so that the first child sits on top and is popped next. Forgetting to reverse gives a valid DFS but visits children right to left.

## Step 4: The code

<!-- CODE:START -->

Full source: [`depth_first_search.dart`](depth_first_search.dart) (run it with `dart run`).

```dart
// Depth-first Search on an n-ary tree (acyclic graph). Returns node names in preorder.
// O(v + e) time, O(v) space.

class Node {
  Node(this.name, [List<Node>? children]) : children = children ?? [];
  final String name;
  final List<Node> children;

  Node addChild(String name) {
    children.add(Node(name));
    return this;
  }

  List<String> depthFirstSearch([List<String>? out]) {
    final result = out ?? <String>[];
    result.add(name);
    for (final child in children) {
      child.depthFirstSearch(result);
    }
    return result;
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `Node(this.name, [List<Node>? children]) : children = children ?? [];` allows building the whole tree in one expression (as the test does) or adding children later.
- `depthFirstSearch([List<String>? out])`: the optional parameter lets the top-level call create the result list and recursive calls share it. Sharing one list avoids creating and concatenating a list per node, which would cost O(n^2) in the worst case.
- `result.add(name);` visits the node before its children: this is **pre-order**.
- `child.depthFirstSearch(result);` recurses into each child in order.

## Step 5: Dry run (call stack)

| call | records | call stack after recording |
|---|---|---|
| A | A | A |
| B | B | A, B |
| E | E | A, B, E (E returns) |
| F | F | A, B, F |
| I | I | A, B, F, I (returns) |
| J | J | A, B, F, J (returns; F, B return) |
| C | C | A, C (returns) |
| D | D | A, D |
| G | G | A, D, G |
| K | K | A, D, G, K (returns; G returns) |
| H | H | A, D, H |

Result: `[A, B, E, F, I, J, C, D, G, K, H]`.

## Complexity

- **Time: O(v + e)**: each vertex is visited once and each parent-child edge is followed once. (In a tree, e = v - 1, so this is O(v).)
- **Space: O(v)**: the output holds v names; the recursion depth is at most v (a chain).

## Common mistakes

- On general graphs, not marking visited nodes (infinite loop on cycles, repeated work on shared nodes).
- In the iterative version, forgetting to push children in reverse.
- Building a new list per call and concatenating: correct output, O(v^2) time.

## DFS vs BFS

| | DFS | BFS (medium 37) |
|---|---|---|
| Data structure | stack (or recursion) | queue |
| Memory | O(depth) | O(width) |
| Finds | a path; explores fully | shortest path in unweighted graphs |
| Typical uses | cycle detection, topological sort, backtracking, connected components | shortest paths, level-order processing |

## Follow-ups

1. **General graph with cycles:** add `visited`; that is the basis of Cycle In Graph (medium 41) and River Sizes (medium 38).
2. **Return the path to a target node:** carry the path, backtrack on return.
3. **Post-order DFS:** record the node after its children. Used for topological sort (hard 27).

## What to remember

DFS = "visit, then recurse into each neighbor". Know the recursive and the explicit-stack versions, and remember `visited` for graphs that are not trees.
