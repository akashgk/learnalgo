# Union Find

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** Disjoint Set Union (DSU)

## Problem
Implement a Union-Find structure over integers with:
- `createSet(value)`: make a new singleton set.
- `find(value)`: return the representative of the value's set, or null if it was never created.
- `union(a, b)`: merge the two sets (no-op if either is unknown or they are already joined).

## Building up the logic
1. Represent each set as a tree; the root is the representative. `find` walks up parent pointers; `union` points one root at the other.
2. Without optimizations, trees can degenerate into chains, making `find` O(n).
3. **Union by rank (or size):** attach the shorter tree under the taller one. Height stays O(log n).
4. **Path compression:** during `find`, repoint every visited node directly to the root, flattening the tree for future queries.
5. With both, any sequence of m operations costs O(m * alpha(n)), where alpha is the inverse Ackermann function (at most 4 for any realistic n). Say "amortized near-constant".

## Complexity
| Operation | Naive | Rank + compression |
|---|---|---|
| createSet | O(1) | O(1) |
| find | O(n) | amortized O(alpha(n)) |
| union | O(n) | amortized O(alpha(n)) |

Space: O(n).

## When to reach for Union-Find
- Dynamic connectivity: "are these two connected?" while edges are only **added**.
- Kruskal's MST (in this repo), counting connected components (LeetCode #323), detecting a cycle in an undirected graph (#684 Redundant Connection), grouping (Accounts Merge #721, Number of Islands II #305).
- It cannot handle edge **deletions** efficiently.
