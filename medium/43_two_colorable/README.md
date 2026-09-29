# Two-Colorable

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Bipartite check by propagating colors

## The problem

Given an **undirected** graph as an adjacency list (each edge appears in both endpoints' lists), return whether its vertices can be colored with two colors so that no edge connects two vertices of the same color. A self-loop makes this impossible.

```
[[1, 2], [0, 2], [0, 1]]           ->  false   (triangle)
[[1, 3], [0, 2], [1, 3], [0, 2]]   ->  true    (square: 0 and 2 blue, 1 and 3 red)
```

## Step 1: Work an example by hand

Color vertex 0 blue. Its neighbors 1 and 2 **must** be red. But 1 and 2 are connected to each other: both red. Conflict. There was no choice we could have made differently: once one vertex's color is fixed, all colors in its connected component are **forced**.

For the square: 0 blue forces 1 and 3 red, which forces 2 blue. Check all edges: every edge connects blue to red. Success.

## Step 2: The algorithm

For each connected component:

1. Color a start vertex (say `true`).
2. Propagate with DFS or BFS: every uncolored neighbor gets the opposite color.
3. If you meet a neighbor that already has the **same** color as the current vertex, return false.

If all components finish without conflict, return true.

## Step 3: The theory worth mentioning

A graph is two-colorable (bipartite) **if and only if it has no cycle of odd length**. Walking around an odd cycle alternates colors an odd number of times, so the start vertex would need both colors. The triangle is the smallest odd cycle.

## Step 4: The code

<!-- CODE:START -->

Full source: [`two_colorable.dart`](two_colorable.dart) (run it with `dart run`).

```dart
// Two-Colorable (bipartite check) on a connected undirected graph (adjacency list).
// DFS assigning alternating colors; conflict means not two-colorable. O(v + e) time, O(v) space.

bool twoColorable(List<List<int>> edges) {
  final color = List<bool?>.filled(edges.length, null);
  for (var start = 0; start < edges.length; start++) {
    if (color[start] != null) continue; // handles disconnected graphs too
    color[start] = true;
    final stack = [start];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      for (final next in edges[node]) {
        if (color[next] == null) {
          color[next] = !color[node]!;
          stack.add(next);
        } else if (color[next] == color[node]) {
          return false; // includes self loops
        }
      }
    }
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `color` is a list of nullable booleans: `null` means uncolored.
- The outer loop starts a new DFS from every uncolored vertex, so disconnected graphs work (even though the original problem promises a connected graph).
- For each neighbor: uncolored gets `!color[node]` and is pushed; same color means a conflict. A self-loop is caught automatically, because a vertex is its own neighbor with the same color.

## Step 5: Dry run on the triangle

| pop | neighbor | neighbor's color | action |
|---|---|---|---|
| 0 (true) | 1 | null | color false, push |
| | 2 | null | color false, push |
| 2 (false) | 0 | true | ok |
| | 1 | **false** | same as 2's color: return false |

## Complexity

- **Time: O(v + e)**.
- **Space: O(v)**.

## Common mistakes

- Checking only neighbors of the start vertex.
- Assuming the graph is connected without saying so.
- Forgetting self-loops.

## Follow-ups

1. **Is Graph Bipartite? (LeetCode #785)** and **Possible Bipartition (#886, "split people who dislike each other into two groups").**
2. **Union-Find alternative:** for each vertex, union all its neighbors into one set; if a vertex ends up in the same set as any neighbor, it is not bipartite.
3. **k-coloring for k >= 3** is NP-complete in general; two colors is the easy special case.

## What to remember

Two-coloring has no real choices: color one vertex and every color in its component is forced. A conflict means an odd cycle.
