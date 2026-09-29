# Detect Arbitrage

**Difficulty:** Very Hard | **Category:** Graphs | **Pattern:** Log transform + Bellman-Ford negative-cycle detection

## The problem

You get a complete matrix of currency exchange rates: `rates[i][j]` is how many units of currency j you receive for one unit of currency i. Return whether an **arbitrage** exists: a sequence of exchanges that starts and ends in the same currency and leaves you with more than you started with.

```
[[1.0,    0.8631, 0.5903],
 [1.1586, 1.0,    0.6849],
 [1.6939, 1.46,   1.0   ]]   ->  true
```

## Step 1: Arbitrage as a cycle

Currencies are vertices; each rate is a directed edge. Exchanging along a cycle multiplies your money by the **product** of the rates. Arbitrage exists iff some cycle has a product **greater than 1**.

## Step 2: Turn products into sums

Shortest-path algorithms work with **sums** of weights. Logarithms turn products into sums:

```
r1 * r2 * ... * rk > 1
<=> log r1 + log r2 + ... + log rk > 0
<=> (-log r1) + (-log r2) + ... + (-log rk) < 0
```

So with edge weights `w = -log(rate)`, arbitrage exists iff the graph has a **negative-weight cycle**.

## Step 3: Bellman-Ford detects negative cycles

Bellman-Ford relaxes **every** edge repeatedly:

- Without negative cycles, shortest paths use at most `n - 1` edges, so after `n - 1` rounds of relaxation all distances are final.
- If some edge can **still** be relaxed in round `n`, distances can keep decreasing forever: there is a negative cycle.

The graph is complete, so every vertex is reachable from vertex 0; a single source is enough.

Floating point: use a tiny epsilon in the comparison so rounding noise is not reported as arbitrage.

## Step 4: Why not Dijkstra?

Dijkstra finalizes the closest vertex assuming later edges cannot make its path shorter. Negative edges break exactly that assumption.

## Step 5: The code

<!-- CODE:START -->

Full source: [`detect_arbitrage.dart`](detect_arbitrage.dart) (run it with `dart run`).

```dart
// Detect Arbitrage: exchangeRates[i][j] = units of currency j per unit of i.
// An arbitrage is a cycle with product of rates > 1, i.e. a negative cycle with weights -log(rate).
// Bellman-Ford. O(n^3) time (complete graph), O(n) space.

import 'dart:math';

bool detectArbitrage(List<List<double>> exchangeRates) {
  final n = exchangeRates.length;
  final w = [
    for (final row in exchangeRates) [for (final r in row) -log(r)],
  ];
  final dist = List<double>.filled(n, double.infinity)..[0] = 0;
  bool relaxAll() {
    var changed = false;
    for (var u = 0; u < n; u++) {
      for (var v = 0; v < n; v++) {
        if (dist[u] + w[u][v] < dist[v] - 1e-12) {
          dist[v] = dist[u] + w[u][v];
          changed = true;
        }
      }
    }
    return changed;
  }

  for (var i = 0; i < n - 1; i++) {
    if (!relaxAll()) return false; // converged early: no negative cycle
  }
  return relaxAll(); // still improving after n - 1 rounds => negative cycle
}
```

<!-- CODE:END -->

### Walkthrough

- `w` stores `-log(rate)` for every pair.
- `relaxAll()` performs one round over all n^2 edges and reports whether anything improved.
- The loop runs up to `n - 1` rounds and stops early if a round changes nothing (then there is no negative cycle).
- One extra round: any improvement means a negative cycle, i.e. arbitrage.

## Step 6: Check the example by hand

Cycle 0 -> 1 -> 2 -> 0: `0.8631 * 0.6849 * 1.6939 = 1.0013 > 1`. That is an arbitrage (about +0.13%), and the algorithm reports true.

## Complexity

- **Time: O(n^3)**: up to n rounds, each relaxing n^2 edges.
- **Space: O(n^2)** for the transformed weights (O(n) for distances).

## Common mistakes

- Using `log(rate)` instead of `-log(rate)` (then you look for positive cycles, which shortest-path algorithms do not detect).
- Exact floating-point comparisons.
- Running Dijkstra.

## Follow-ups

1. **Return the arbitrage cycle:** store predecessors; after round n, from any vertex relaxed in that round, follow predecessors n times to land inside the cycle, then follow until a vertex repeats.
2. **Cheapest Flights Within K Stops (LeetCode #787):** Bellman-Ford limited to k + 1 rounds.
3. **Floyd-Warshall:** also detects negative cycles (a negative value on the diagonal), O(n^3).

## What to remember

Products become sums under logarithms; "product > 1 around a cycle" becomes "negative cycle", which Bellman-Ford detects with one extra relaxation round.
