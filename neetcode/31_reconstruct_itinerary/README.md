# Reconstruct Itinerary

**Difficulty:** Hard | **Category:** Advanced Graphs | **Pattern:** Eulerian path (Hierholzer's algorithm) | **Source:** LeetCode 332; NeetCode 150

## The problem

Each ticket is a flight `[from, to]`. Starting at `"JFK"`, use **every ticket exactly once**. If several itineraries are possible, return the lexicographically smallest one (compare the sequences of airport codes). A valid itinerary is guaranteed.

```
[["MUC","LHR"], ["JFK","MUC"], ["SFO","SJC"], ["LHR","SFO"]]
->  JFK MUC LHR SFO SJC

[["JFK","SFO"], ["JFK","ATL"], ["SFO","ATL"], ["ATL","JFK"], ["ATL","SFO"]]
->  JFK ATL JFK SFO ATL SFO
```

## Step 1: Name the problem

Airports are nodes, tickets are directed edges, and "use every edge exactly once" is an **Eulerian path**. Recognizing this is most of the difficulty.

## Step 2: Why greedy "smallest next airport" fails

```
tickets: JFK->KUL, JFK->NRT, NRT->JFK
```

Greedy goes JFK -> KUL (smallest) and gets stuck with two tickets unused. The correct answer is JFK -> NRT -> JFK -> KUL. Greedy is right **except** when it walks into a dead end too early.

Backtracking fixes it (try smallest first, undo on failure) but can be exponential in bad cases.

## Step 3: Hierholzer's algorithm

Walk greedily (smallest destination first), but instead of recording airports when you **arrive**, record them when you **get stuck** (no unused tickets out of the current airport). Then reverse.

Why this works: when you are stuck at airport X, X must be the **end** of whatever remains of the route, because every other part of the itinerary can be spliced in before it. In the example:

1. Stack: JFK -> KUL. KUL has no tickets: emit KUL. Back at JFK.
2. JFK still has NRT: stack JFK -> NRT -> JFK. JFK has no tickets left: emit JFK. NRT: emit NRT. JFK: emit JFK.
3. Emitted: KUL, JFK, NRT, JFK. Reversed: **JFK NRT JFK KUL**.

The detour that got stuck (KUL) ends up **last**, and the loop found later (NRT -> JFK) is spliced in before it. Taking the smallest destination first at every step makes the result lexicographically smallest.

## Step 4: Implementation details

- Sort each airport's destinations in **descending** order and pop from the end: that yields the smallest in O(1) (`removeLast` on a list).
- Use an explicit stack instead of recursion.

## Step 5: The code

<!-- CODE:START -->

Full source: [`reconstruct_itinerary.dart`](reconstruct_itinerary.dart) (run it with `dart run`).

```dart
// Reconstruct Itinerary: use every ticket [from, to] exactly once, starting at "JFK"; if several
// itineraries work, return the lexicographically smallest. An Eulerian path problem.
// Hierholzer's algorithm, always taking the smallest remaining destination, emitting airports in
// post-order and reversing. O(E log E) time (sorting), O(E) space.

List<String> findItinerary(List<List<String>> tickets) {
  // For each airport, destinations sorted DESCENDING so removeLast() yields the smallest.
  final graph = <String, List<String>>{};
  for (final t in tickets) {
    graph.putIfAbsent(t[0], () => []).add(t[1]);
  }
  for (final list in graph.values) {
    list.sort((a, b) => b.compareTo(a));
  }
  final route = <String>[];
  final stack = ['JFK'];
  while (stack.isNotEmpty) {
    final dests = graph[stack.last];
    if (dests != null && dests.isNotEmpty) {
      stack.add(dests.removeLast()); // follow the smallest unused ticket
    } else {
      route.add(stack.removeLast()); // dead end: this airport is final among what remains
    }
  }
  return route.reversed.toList();
}
```

<!-- CODE:END -->

### Walkthrough

- `graph` maps each airport to its outgoing destinations, sorted descending.
- The loop looks at the top of the stack: if it has unused tickets, fly (push the smallest destination); otherwise it is finished, so move it to `route`.
- `route.reversed` is the itinerary.

## Step 6: Dry run

Second example. Destinations: JFK: [SFO, ATL] (pop ATL first), ATL: [SFO, JFK] (pop JFK first), SFO: [ATL].

| stack | action | route |
|---|---|---|
| JFK | fly to ATL | |
| JFK ATL | fly to JFK | |
| JFK ATL JFK | fly to SFO | |
| JFK ATL JFK SFO | fly to ATL | |
| JFK ATL JFK SFO ATL | fly to SFO | |
| JFK ATL JFK SFO ATL SFO | stuck: emit SFO | SFO |
| ... every airport is now stuck | emit ATL, SFO, JFK, ATL, JFK | SFO ATL SFO JFK ATL JFK |

Reversed: **JFK ATL JFK SFO ATL SFO**.

## Complexity

- Time: **O(E log E)** for sorting destinations; the walk itself is O(E).
- Space: **O(E)**.

## Edge cases

- Repeated tickets (same from and to): both copies are in the list and each is used once.
- A single ticket.

## Common mistakes

- Pure greedy without handling dead ends.
- Recording airports on arrival instead of when stuck.
- Sorting ascending and removing from the front of a list (O(n) per removal).

## Follow-ups you should be ready for

1. **Existence of an Eulerian path.** In a directed graph: at most one node with out - in = 1 (the start), at most one with in - out = 1 (the end), all others balanced, and all edges connected.
2. **Valid Arrangement of Pairs (LeetCode 2097).** Same algorithm; you must find the start node yourself.
3. **Cracking the Safe (LeetCode 753).** De Bruijn sequence via an Eulerian circuit.

## What to remember

"Use every edge exactly once" is an Eulerian path. Hierholzer: walk greedily, emit a node when it has no unused edges, reverse at the end.
