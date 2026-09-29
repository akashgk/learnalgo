# Union Find

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** Disjoint Set Union (DSU)

## The problem

Implement a Union-Find (disjoint set) data structure over integers with three operations:

- `createSet(value)`: create a new set containing only `value`;
- `find(value)`: return the **representative** of the set containing `value` (the same representative for every member of a set), or null if `value` was never created;
- `union(a, b)`: merge the sets containing `a` and `b` (no-op if either is unknown or they are already in the same set).

## Step 1: The idea

Represent each set as a **tree** of parent pointers. The root of the tree is the set's representative.

- `find(x)`: follow parent pointers from x until you reach a node that is its own parent.
- `union(a, b)`: find both roots and make one root the parent of the other.

```
createSet 1..5:      1   2   3   4   5    (each its own root)
union(1, 2):         1   3   4   5
                     |
                     2
union(3, 4):         1   3   5
                     |   |
                     2   4
union(2, 4):  find(2) = 1, find(4) = 3, attach 3 under 1:
                     1       5
                    / \
                   2   3
                       |
                       4
```

## Step 2: The problem with the naive version

If you always attach the first root under the second, a sequence of unions can build a **chain**: `find` on the bottom element then walks n pointers. Operations degrade to O(n).

## Step 3: Two optimizations

**Union by rank (or by size):** attach the **shorter** tree under the taller one. A tree's height then only grows when two trees of equal height merge, which keeps height at most log2(n).

**Path compression:** during `find`, after locating the root, repoint **every** node on the path directly to the root. The next `find` on any of them takes one step.

With both, any sequence of m operations costs O(m * alpha(n)), where alpha is the **inverse Ackermann function**. It grows so slowly that alpha(n) <= 4 for any n you will ever see. In interviews, say "amortized nearly constant time".

## Step 4: The code

<!-- CODE:START -->

Full source: [`union_find.dart`](union_find.dart) (run it with `dart run`).

```dart
// Union Find (Disjoint Set Union) with path compression and union by rank.
// createSet/find/union in amortized O(alpha(n)) (effectively constant). O(n) space.

class UnionFind {
  final _parent = <int, int>{};
  final _rank = <int, int>{};

  void createSet(int value) {
    _parent[value] = value;
    _rank[value] = 0;
  }

  /// Representative of [value]'s set, or null if [value] was never created.
  int? find(int value) {
    if (!_parent.containsKey(value)) return null;
    var root = value;
    while (_parent[root] != root) {
      root = _parent[root]!;
    }
    // Path compression: point every node on the path directly at the root.
    var node = value;
    while (node != root) {
      final next = _parent[node]!;
      _parent[node] = root;
      node = next;
    }
    return root;
  }

  void union(int a, int b) {
    final ra = find(a), rb = find(b);
    if (ra == null || rb == null || ra == rb) return;
    // Union by rank: attach the shorter tree under the taller one.
    final rankA = _rank[ra]!, rankB = _rank[rb]!;
    if (rankA < rankB) {
      _parent[ra] = rb;
    } else if (rankA > rankB) {
      _parent[rb] = ra;
    } else {
      _parent[rb] = ra;
      _rank[ra] = rankA + 1;
    }
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `_parent` and `_rank` are maps so arbitrary integers can be used as values.
- `find`:
  - returns null for unknown values;
  - first loop: walk up to the root;
  - second loop: path compression, pointing every node on the path straight at the root. (Save `next` before overwriting the parent pointer.)
- `union`:
  - finds both roots; returns early if either is unknown or they are equal;
  - attaches the lower-rank root under the higher-rank root; on a tie, picks one and increases its rank.

## Step 5: Dry run of the test

| operation | parent after (non-root entries) | ranks changed |
|---|---|---|
| createSet 1..5 | all roots | all 0 |
| union(1, 2) | 2 -> 1 | rank[1] = 1 |
| union(3, 4) | 4 -> 3 | rank[3] = 1 |
| union(2, 4) | roots 1 and 3, equal rank: 3 -> 1 | rank[1] = 2 |
| find(3) | root 1 | |
| find(1) == find(3) | both 1: same set | |

## Complexity

| Operation | Naive | Rank + path compression |
|---|---|---|
| createSet | O(1) | O(1) |
| find | O(n) | amortized O(alpha(n)) |
| union | O(n) | amortized O(alpha(n)) |

Space: O(n).

## When to reach for Union-Find

- **Dynamic connectivity** with only additions: "are x and y connected?" as edges keep arriving.
- **Kruskal's MST** (hard 28): "would this edge create a cycle?".
- **Counting components** (LeetCode #323, #547).
- **Cycle detection in undirected graphs** (#684 Redundant Connection).
- **Grouping by equivalence:** Accounts Merge (#721), Similar String Groups (#839), Number of Islands II (#305, cells added over time).

Limitation: Union-Find cannot efficiently **split** sets (edge deletions).

## Common mistakes

- Forgetting to union the **roots** (attaching `a` directly under `b` breaks the trees).
- Path compression that loses the pointer to the next node.

## What to remember

Sets as parent-pointer trees; find walks to the root; union links roots. Union by rank + path compression make both nearly O(1).
