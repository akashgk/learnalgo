# Floyd-Warshall (All-Pairs Shortest Paths)

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** DP over allowed intermediate vertices | **Source:** Striver A2Z; LeetCode 1334 is a direct application

## The problem

Given a directed weighted graph (weights may be negative), compute the shortest distance between **every** pair of vertices. Report a negative cycle if one exists.

```
edges: 0->1 3, 1->0 2, 0->3 5, 1->3 4, 3->2 2, 2->1 1

dist =  0  3  7  5
        2  0  6  4
        3  1  0  5
        5  3  2  0
```

## Step 1: Options for all pairs

| Approach | Time | Negative edges? |
|---|---|---|
| Dijkstra from every vertex (binary heap) | O(V * E log V) | no |
| Bellman-Ford from every vertex | O(V^2 * E) | yes |
| **Floyd-Warshall** | **O(V^3)** | yes |

For dense graphs (E close to V^2), Floyd-Warshall is as good as repeated Dijkstra, handles negative edges, and is about ten lines long.

## Step 2: The DP

Define `d_k[i][j]` = the shortest path from `i` to `j` that only uses vertices from `{0, 1, ..., k}` as **intermediate** stops.

- `d_{-1}[i][j]` is the direct edge weight (or infinity, 0 on the diagonal).
- To compute `d_k[i][j]`, a shortest path using intermediates `{0..k}` either **does not use k** (`d_{k-1}[i][j]`) or **uses k exactly once**, splitting into `i -> k` and `k -> j`, each using only `{0..k-1}`:

```
d_k[i][j] = min(d_{k-1}[i][j], d_{k-1}[i][k] + d_{k-1}[k][j])
```

After `k = V - 1`, all vertices are allowed: true shortest paths.

**Why one 2-D array is enough (no k dimension):** in round k, the entries `d[i][k]` and `d[k][j]` do not change (going through k to reach k cannot help unless there is a negative cycle). So updating in place reads the same values the 3-D version would.

**The loop order matters: `k` must be the outermost loop.** The DP is over k; i and j just fill the table for each k. Putting k inside is a classic bug that gives wrong answers.

## Step 3: Negative cycles

If a negative cycle passes through `i`, then after the algorithm `d[i][i] < 0` (going around the cycle beats the empty path). Check the diagonal at the end.

## Step 4: The code

<!-- CODE:START -->

Full source: [`floyd_warshall.dart`](floyd_warshall.dart) (run it with `dart run`).

```dart
// Floyd-Warshall: shortest distances between every pair of vertices (negative edges allowed).
// dist[i][j] is improved using intermediate vertex k, for k = 0..n-1 in the outer loop.
// Detects negative cycles (dist[i][i] < 0). O(V^3) time, O(V^2) space.

const inf = 1 << 50;

/// Returns the distance matrix (inf = unreachable), or null if a negative cycle exists.
List<List<int>>? floydWarshall(int n, List<List<int>> edges) {
  final dist = List.generate(n, (i) => List<int>.generate(n, (j) => i == j ? 0 : inf));
  for (final e in edges) {
    if (e[2] < dist[e[0]][e[1]]) dist[e[0]][e[1]] = e[2]; // keep the cheapest parallel edge
  }
  for (var k = 0; k < n; k++) {
    // After this round, dist[i][j] is the shortest path using only intermediates from {0..k}.
    for (var i = 0; i < n; i++) {
      if (dist[i][k] == inf) continue;
      for (var j = 0; j < n; j++) {
        if (dist[k][j] == inf) continue;
        final through = dist[i][k] + dist[k][j];
        if (through < dist[i][j]) dist[i][j] = through;
      }
    }
  }
  for (var i = 0; i < n; i++) {
    if (dist[i][i] < 0) return null;
  }
  return dist;
}
```

<!-- CODE:END -->

### Walkthrough

- `inf = 1 << 50` stands for "no path". The `continue` checks skip infinite entries so that `inf + negative` never looks like a real path.
- Parallel edges keep the cheapest.
- The diagonal check returns null for a negative cycle.

## Step 5: Dry run

Starting matrix (direct edges):

```
0    3    inf  5
2    0    inf  4
inf  1    0    inf
inf  inf  2    0
```

| k | improvements |
|---|---|
| 0 | none: only vertex 1 has an edge into 0, and 1 -> 0 -> 3 = 7 is worse than the direct 1 -> 3 = 4 |
| 1 | d[2][0] = inf -> 3 (2 -> 1 -> 0), d[2][3] = inf -> 5 (2 -> 1 -> 3) |
| 2 | d[3][0] = inf -> 5 (3 -> 2, then 2 -> 1 -> 0), d[3][1] = inf -> 3 (3 -> 2 -> 1) |
| 3 | d[0][2] = inf -> 7 (0 -> 3 -> 2), d[1][2] = inf -> 6 (1 -> 3 -> 2) |

The final matrix is the one at the top.

## Complexity

- Time: **O(V^3)**.
- Space: **O(V^2)**.

## Edge cases

- Unreachable pairs stay `inf`.
- Negative edges without negative cycles: correct distances.
- Negative cycle: detected via the diagonal.

## Common mistakes

- Putting `k` in an inner loop.
- Adding to infinity (overflow or fake paths). Guard with `continue` or use a large but safe constant.
- Initializing the diagonal to infinity instead of 0.

## Follow-ups you should be ready for

1. **Reconstruct paths.** Keep `next[i][j]`, updated to `next[i][k]` when going through k improves the distance.
2. **Transitive closure.** Same loops with booleans: `reach[i][j] |= reach[i][k] && reach[k][j]`.
3. **Find the City With the Smallest Number of Neighbors at a Threshold Distance (LeetCode 1334).** Floyd-Warshall, then count per row.
4. **Which vertices are affected by a negative cycle?** Any pair `(i, j)` with some `k` where `d[k][k] < 0`, `d[i][k] < inf`, and `d[k][j] < inf` has distance minus infinity.

## What to remember

Floyd-Warshall is a DP over "which vertices may be used as intermediates". Outer loop over k, then i, then j; negative cycle if any `d[i][i] < 0`.
