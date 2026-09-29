# Apartment Hunting

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Nearest-occurrence precomputation with two sweeps

## The problem

A street is a list of blocks. Each block is a map saying which buildings (gym, school, store, ...) it contains. Given a list of **required** buildings, choose the block for your apartment that **minimizes the farthest distance** you would have to walk to reach any required building (for each requirement you walk to its nearest block). Return that block's index. Every requirement exists somewhere on the street.

```
blocks = [
  {gym: false, school: true,  store: false},
  {gym: true,  school: false, store: false},
  {gym: true,  school: true,  store: false},
  {gym: false, school: true,  store: false},
  {gym: false, school: true,  store: true},
]
reqs = [gym, school, store]   ->  3
```

From block 3: nearest gym is 1 block away, school 0, store 1. The farthest walk is 1, and no other block does better.

## Step 1: Understand the objective

For block `i`: `cost(i) = max over requirements r of distance(i, nearest block with r)`. We want `argmin cost(i)`. This is a **minimax** objective (minimize the worst case). Read carefully: minimizing the **sum** of distances is a different problem with a different answer.

## Step 2: Brute force

For each block and each requirement, scan outward to the nearest block with that requirement: O(b) per pair. **O(b^2 * r)** total.

## Step 3: Precompute nearest distances

**Duplicated work:** "distance from block i to the nearest block with r" is recomputed from scratch for every block. Compute it for all blocks at once, per requirement, with two sweeps:

- **Left to right:** remember the index of the last block that had `r`. Distance to the nearest `r` on the left is `i - last`.
- **Right to left:** remember the last block with `r` seen from the right. Distance to the nearest `r` on the right is `last - i`.
- Take the minimum of the two.

This "previous occurrence / next occurrence" double sweep is a reusable trick for any "nearest X to each position" question.

Then compute each block's worst distance and pick the minimum.

## Step 4: The code

<!-- CODE:START -->

Full source: [`apartment_hunting.dart`](apartment_hunting.dart) (run it with `dart run`).

```dart
// Apartment Hunting: choose the block minimizing the farthest distance to any required
// building. For each requirement, nearest distance per block via left and right sweeps.
// O(b * r) time, O(b * r) space.

int apartmentHunting(List<Map<String, bool>> blocks, List<String> reqs) {
  final b = blocks.length;
  // nearest[r][i] = distance from block i to the nearest block with requirement r
  final nearest = <List<int>>[];
  const inf = 1 << 40;
  for (final req in reqs) {
    final dist = List<int>.filled(b, inf);
    var last = -1;
    for (var i = 0; i < b; i++) {
      if (blocks[i][req] ?? false) last = i;
      if (last != -1) dist[i] = i - last;
    }
    last = -1;
    for (var i = b - 1; i >= 0; i--) {
      if (blocks[i][req] ?? false) last = i;
      if (last != -1 && last - i < dist[i]) dist[i] = last - i;
    }
    nearest.add(dist);
  }
  var bestIdx = 0, bestWorst = inf;
  for (var i = 0; i < b; i++) {
    var worst = 0;
    for (final dist in nearest) {
      if (dist[i] > worst) worst = dist[i];
    }
    if (worst < bestWorst) {
      bestWorst = worst;
      bestIdx = i;
    }
  }
  return bestIdx;
}
```

<!-- CODE:END -->

### Walkthrough

- `nearest` holds one distance list per requirement.
- The two sweeps fill `dist` for one requirement; `inf` marks "none seen yet" during the first sweep.
- The final loop computes each block's worst distance and keeps the block with the smallest worst distance (ties keep the lower index because of strict `<`).

## Step 5: Dry run

| block | gym dist | school dist | store dist | worst |
|---|---|---|---|---|
| 0 | 1 | 0 | 4 | 4 |
| 1 | 0 | 1 | 3 | 3 |
| 2 | 0 | 0 | 2 | 2 |
| 3 | 1 | 0 | 1 | **1** |
| 4 | 2 | 0 | 0 | 2 |

Answer: block 3.

## Complexity

- **Time: O(b * r)**: two sweeps per requirement plus the final scan.
- **Space: O(b * r)** for the distance lists (O(b) if you keep a running "worst" array and discard each requirement's list after use).

## Common mistakes

- Optimizing the sum instead of the maximum.
- Only sweeping in one direction (misses nearer buildings on the other side).

## Follow-ups

1. **Shortest Distance to a Character (LeetCode #821):** exactly one requirement.
2. **Minimize the sum of distances on a line:** the median of the positions (for one building per requirement).
3. **2D version (best meeting point, #296):** separate x and y, take medians.

## What to remember

"Nearest X for every position" = one left-to-right sweep and one right-to-left sweep remembering the last X seen. Then combine per position.
