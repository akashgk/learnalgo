# Largest Island

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Label components, then evaluate each candidate cell

## The problem

A matrix uses **0 for land and 1 for water** (AlgoExpert's convention; LeetCode's version flips it). An island is a group of land cells connected horizontally or vertically. You may turn **at most one** water cell into land. Return the size of the largest island possible.

```
[[0, 1, 1],
 [0, 0, 1],
 [1, 1, 0]]   ->  5

Turning (2, 1) into land connects the 3-cell island {(0,0),(1,0),(1,1)}
with the 1-cell island {(2,2)}: 3 + 1 + 1 = 5.
```

## Step 1: Brute force

For each water cell: flip it, run a flood fill to find the largest island, flip it back. O(w * h) water cells times O(w * h) flood fill: **O((w * h)^2)**.

## Step 2: What does flipping one cell do?

Flipping water cell X merges X with **the islands that touch it** (its up to 4 land neighbors). The new island size is:

```
1 + (sum of sizes of the DISTINCT islands adjacent to X)
```

So if we know, for every land cell, **which island** it belongs to and **how big** that island is, each water cell can be evaluated in O(1).

## Step 3: Two passes

1. **Label islands:** flood-fill each island once, writing an island id into every one of its cells, and record `sizes[id]`.
2. **Evaluate water cells:** for each water cell, collect the ids of its land neighbors into a **set** (two neighbors often belong to the same island; counting it twice is the classic bug), and compute `1 + sum of their sizes`.

Also consider the case with no water to flip: the answer is then the largest existing island.

## Step 4: The code

<!-- CODE:START -->

Full source: [`largest_island.dart`](largest_island.dart) (run it with `dart run`).

```dart
// Largest Island: 0 = land, 1 = water (AlgoExpert's convention). You may turn one water cell
// into land. Return the largest island size achievable (4-directional adjacency).
// Label each island with an id and size, then try each water cell. O(w * h) time and space.

int largestIsland(List<List<int>> matrix) {
  final rows = matrix.length, cols = matrix[0].length;
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  final islandId = List.generate(rows, (_) => List<int>.filled(cols, -1));
  final sizes = <int>[];

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 0 || islandId[r][c] != -1) continue;
      final id = sizes.length;
      var size = 0;
      final stack = [(r, c)];
      islandId[r][c] = id;
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        size++;
        for (final (dr, dc) in dirs) {
          final nr = cr + dr, nc = cc + dc;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (matrix[nr][nc] == 0 && islandId[nr][nc] == -1) {
            islandId[nr][nc] = id;
            stack.add((nr, nc));
          }
        }
      }
      sizes.add(size);
    }
  }

  var best = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a > b ? a : b);
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (matrix[r][c] != 1) continue;
      final touching = <int>{}; // distinct islands around this water cell
      for (final (dr, dc) in dirs) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && islandId[nr][nc] != -1) {
          touching.add(islandId[nr][nc]);
        }
      }
      final size = 1 + touching.fold<int>(0, (s, id) => s + sizes[id]);
      if (size > best) best = size;
    }
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `islandId` stores -1 for unlabeled cells, or the island id.
- The first double loop runs an iterative DFS from every unlabeled land cell, labeling and counting its island.
- `best` starts as the largest existing island (0 if there is no land).
- The second double loop evaluates every water cell with a set of adjacent ids.
- `fold<int>` sums the sizes (the explicit type argument keeps Dart's analyzer happy).

## Step 5: Dry run

Islands: id 0 = `{(0,0), (1,0), (1,1)}` size 3; id 1 = `{(2,2)}` size 1.

| water cell | adjacent island ids | size if flipped |
|---|---|---|
| (0, 1) | {0} | 4 |
| (0, 2) | {} | 1 |
| (1, 2) | {1} | 2 |
| (2, 0) | {0} | 4 |
| (2, 1) | {0, 1} | **5** |

## Complexity

- **Time: O(w * h)**: labeling visits every cell once; each water cell checks 4 neighbors.
- **Space: O(w * h)** for the id grid and the DFS stack.

## Common mistakes

- Counting the same island twice when it touches the water cell from two sides.
- Forgetting the all-land case (no cell to flip) or the all-water case (answer 1).
- Mixing up the 0/1 convention.

## Follow-ups

1. **Making A Large Island (LeetCode #827):** identical with 1 as land.
2. **Label once, answer many queries:** the same "component id + component size" preprocessing answers queries like "how big is the region containing cell X?" in O(1).

## What to remember

Label connected components with ids and sizes once; then the effect of a local change can be computed in O(1) by looking at the distinct neighboring components.
