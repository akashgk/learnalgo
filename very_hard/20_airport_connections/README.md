# Airport Connections

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Strongly connected components + condensation DAG

## The problem

You get a list of airports, a list of **one-way** routes `[from, to]`, and a starting airport. Return the **minimum number of new one-way routes** (each departing from the starting airport) needed so that **every** airport is reachable from the starting airport.

```
18 airports, 19 routes, start = "LGA"  ->  3
(one valid choice: add LGA -> TLV, LGA -> SFO, LGA -> EWR)
```

## Step 1: Think about what one new route buys you

Adding a route `start -> X` makes **everything reachable from X** reachable. Airports already reachable from the start need nothing. So the question is: what is the smallest set of airports `X1, X2, ...` such that together they reach every airport that is currently unreachable?

## Step 2: Cycles collapse

If airports are on a common cycle (A -> B -> C -> A), reaching any one of them reaches all of them. So group airports into **strongly connected components** (SCCs): maximal groups in which every airport can reach every other. Replace each group by a single node. The result (the **condensation**) is always a **DAG**: if two groups could reach each other, they would be one group.

## Step 3: Count the sources

In a DAG, every node is reachable from some **source** (a node with no incoming edges). And a source cannot be reached from anything else, so each source (other than the start's own component) **needs its own new route**. Routes to all sources are also **enough**, since everything is reachable from some source.

```
answer = number of source components in the condensation, excluding the start's component
```

## Step 4: Finding SCCs: Kosaraju's algorithm

1. Run DFS on the graph and record vertices in order of **finishing** time.
2. Reverse all edges.
3. Process vertices in **decreasing** finish time; each DFS on the reversed graph from an unassigned vertex collects exactly one SCC.

(Tarjan's algorithm finds SCCs in a single DFS using low-link values; either is fine to name.)

Then mark every component that receives an edge from a **different** component. The unmarked ones are sources.

## Step 5: The code

<!-- CODE:START -->

Full source: [`airport_connections.dart`](airport_connections.dart) (run it with `dart run`).

```dart
// Airport Connections: minimum number of new one-way routes from the starting airport's
// network so every airport becomes reachable.
// Collapse strongly connected components (Kosaraju); the answer is the number of components
// with no incoming edges, excluding the start's component. O(a + r) time and space.

int airportConnections(List<String> airports, List<List<String>> routes, String startingAirport) {
  final id = {for (var i = 0; i < airports.length; i++) airports[i]: i};
  final n = airports.length;
  final adj = List.generate(n, (_) => <int>[]);
  final radj = List.generate(n, (_) => <int>[]);
  for (final [from, to] in routes) {
    adj[id[from]!].add(id[to]!);
    radj[id[to]!].add(id[from]!);
  }

  // Pass 1: order vertices by DFS finish time.
  final visited = List<bool>.filled(n, false);
  final order = <int>[];
  void dfs1(int u) {
    visited[u] = true;
    for (final v in adj[u]) {
      if (!visited[v]) dfs1(v);
    }
    order.add(u);
  }

  for (var u = 0; u < n; u++) {
    if (!visited[u]) dfs1(u);
  }

  // Pass 2: DFS on the reversed graph in reverse finish order; each tree is one SCC.
  final comp = List<int>.filled(n, -1);
  var compCount = 0;
  void dfs2(int u, int c) {
    comp[u] = c;
    for (final v in radj[u]) {
      if (comp[v] == -1) dfs2(v, c);
    }
  }

  for (final u in order.reversed) {
    if (comp[u] == -1) dfs2(u, compCount++);
  }

  final hasIncoming = List<bool>.filled(compCount, false);
  for (var u = 0; u < n; u++) {
    for (final v in adj[u]) {
      if (comp[u] != comp[v]) hasIncoming[comp[v]] = true;
    }
  }
  final startComp = comp[id[startingAirport]!];
  var answer = 0;
  for (var c = 0; c < compCount; c++) {
    if (!hasIncoming[c] && c != startComp) answer++;
  }
  return answer;
}
```

<!-- CODE:END -->

### Walkthrough

- `id` maps airport names to indices; `adj` and `radj` are the graph and its reverse.
- `dfs1` records finish order.
- `dfs2` assigns component numbers on the reversed graph.
- `hasIncoming[c]` is set for any component that receives an edge from another component.
- The answer counts components with no incoming edges, excluding the start's component.

## Step 6: Small dry run

`airports = [A, B, C]`, routes `B -> C`, `C -> B`, start A.

- SCCs: `{A}`, `{B, C}` (a cycle).
- Condensation: no edges between the two components. Both are sources.
- Excluding the start's component `{A}`: one source left: answer **1** (add `A -> B` or `A -> C`).

## Complexity

- **Time: O(a + r)**: two DFS passes and one scan of the edges.
- **Space: O(a + r)** for the graph and its reverse.

Note: very deep graphs can overflow a recursive DFS; an iterative DFS avoids that.

## Comparison with AlgoExpert's approach

The reference solution uses a greedy over "how many unreachable airports each unreachable airport can reach", which is O(a * (a + r)) time. The SCC approach is faster and easier to prove optimal (the source-counting argument above).

## Common mistakes

- Counting unreachable airports instead of source components (overcounts when cycles or chains exist).
- Counting the start's own component when it has no incoming edges.

## Follow-ups

1. **Minimum edges to make a whole DAG strongly connected:** `max(#sources, #sinks)` (0 if already one component).
2. **Critical Connections (LeetCode #1192)** and **Two-Edge-Connected Graph (very hard 22):** other DFS low-link applications.

## What to remember

Collapse strongly connected components to get a DAG; in a DAG, sources are exactly the nodes that must be targeted directly.
