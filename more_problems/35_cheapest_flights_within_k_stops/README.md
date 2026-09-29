# Cheapest Flights Within K Stops

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Bellman-Ford limited to k + 1 rounds | **Source:** LeetCode 787; Striver A2Z, NeetCode 150

## The problem

`n` cities, directed flights `[from, to, price]`. Find the cheapest price from `src` to `dst` using **at most `k` stops** (so at most `k + 1` flights). Return -1 if impossible.

```
flights: 0->1 100, 1->2 100, 2->0 100, 1->3 600, 2->3 200
src 0, dst 3, k = 1   ->  700   (0 -> 1 -> 3)
src 0, dst 3, k = 2   ->  400   (0 -> 1 -> 2 -> 3)
```

## Step 1: Why plain Dijkstra is not enough

Dijkstra finds the cheapest path, ignoring the number of edges. The cheapest path to city 3 is 0 -> 1 -> 2 -> 3 (400), but it uses 2 stops. With k = 1 it is not allowed. Worse, Dijkstra **finalizes** each city at its cheapest cost and never revisits it, but a **more expensive route with fewer flights** might be the one that can still be extended within the limit.

(Dijkstra can be adapted by making the state `(city, flights used)`, which works, but it is more to explain.)

## Step 2: Bellman-Ford counts edges naturally

Bellman-Ford relaxes every edge in rounds. The key fact: **after round r, `cost[v]` is the cheapest price to reach `v` using at most r edges**, provided each round only extends paths from the **previous** round. So running exactly `k + 1` rounds answers the question directly.

## Step 3: The snapshot detail (the whole difficulty)

Standard Bellman-Ford updates `cost` in place. Within one round, an edge relaxed early can feed an edge relaxed later, so a single round may extend a path by **several** edges. For shortest paths without a limit that is harmless (it just converges faster). Here it breaks the count.

Example with k = 0 (one flight only): the flights `0 -> 1 (100)` and `1 -> 3 (600)`. If updated in place, round 1 sets `cost[1] = 100` and then, in the same round, `cost[3] = 700` through city 1: a two-flight path counted as one.

Fix: each round reads from a **copy** of the previous round's costs and writes into the new array. Every round then adds exactly one flight.

## Step 4: The code

<!-- CODE:START -->

Full source: [`cheapest_flights_within_k_stops.dart`](cheapest_flights_within_k_stops.dart) (run it with `dart run`).

```dart
// Cheapest Flights Within K Stops: cheapest price from src to dst using at most k stops
// (at most k + 1 flights), or -1. Bellman-Ford limited to k + 1 rounds, relaxing from a
// snapshot of the previous round so a round never chains two flights. O(k * E) time, O(n) space.

int findCheapestPrice(int n, List<List<int>> flights, int src, int dst, int k) {
  const inf = 1 << 60;
  var cost = List<int>.filled(n, inf);
  cost[src] = 0;
  for (var round = 0; round <= k; round++) {
    // After round r, cost[v] = cheapest price using at most r + 1 flights.
    final next = [...cost];
    for (final f in flights) {
      final (from, to, price) = (f[0], f[1], f[2]);
      if (cost[from] != inf && cost[from] + price < next[to]) next[to] = cost[from] + price;
    }
    cost = next;
  }
  return cost[dst] == inf ? -1 : cost[dst];
}
```

<!-- CODE:END -->

### Walkthrough

- `cost[src] = 0`, all others infinity.
- `for (round = 0; round <= k; round++)`: k + 1 rounds, one per allowed flight.
- `next = [...cost]` keeps paths with fewer flights (not taking a flight this round is allowed), and relaxations read `cost[from]` from the previous round only.

## Step 5: Dry run

k = 1:

| after round | cost[0] | cost[1] | cost[2] | cost[3] |
|---|---|---|---|---|
| start | 0 | inf | inf | inf |
| 1 (<= 1 flight) | 0 | 100 | inf | inf |
| 2 (<= 2 flights) | 0 | 100 | 200 | **700** |

In round 2, the edge `2 -> 3` reads `cost[2]` from round 1, which is still inf, so the 3-flight route is not counted. With k = 2 a third round would give `cost[3] = min(700, 200 + 200) = 400`.

## Complexity

- Time: **O(k * E)**. Each round scans all flights once.
- Space: **O(n)** for two cost arrays.

## Edge cases

- `src == dst`: 0.
- No route within the limit: -1.
- Cycles (2 -> 0): harmless, since each round adds exactly one flight and prices are non-negative.

## Common mistakes

- Updating costs in place (paths use more flights than allowed).
- Running k rounds instead of k + 1 (k stops means k + 1 flights).
- Using Dijkstra with a visited set on cities only.

## Follow-ups you should be ready for

1. **BFS by levels with pruning.** Queue of (city, cost), process level by level up to k + 1 levels, only enqueue when a cheaper cost is found for that level. Same complexity idea.
2. **Dijkstra on (city, stops) states.** Priority queue ordered by cost; skip a state if it exceeds k stops. Useful when prices vary a lot and k is large.
3. **Negative prices.** Bellman-Ford still works (no infinite-descent issue because the number of rounds is bounded).

## What to remember

Bellman-Ford's round r means "paths with at most r edges", but only if each round relaxes from a snapshot of the previous round. Limit the rounds to limit the edges.
