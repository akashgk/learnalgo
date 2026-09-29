# Disk Stacking

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Sort + LIS-style DP over a partial order

## The problem

Each disk is `[width, depth, height]`. You want to build the **tallest** possible stack. A disk can be placed on another only if it is **strictly smaller in all three dimensions**. Disks cannot be rotated. Return the disks in the tallest stack, ordered from the top (smallest) to the bottom. Assume a unique answer.

```
[[2, 1, 2], [3, 2, 3], [2, 2, 8], [2, 3, 4], [1, 3, 1], [4, 4, 5]]
->  [[2, 1, 2], [3, 2, 3], [4, 4, 5]]      (height 2 + 3 + 5 = 10)
```

## Step 1: Recognize the pattern

"Choose a sequence where each item is strictly smaller than the next in every dimension, maximizing a sum" is an **increasing subsequence** problem in several dimensions. Like Max Sum Increasing Subsequence, but "increasing" means "fits on top".

## Step 2: Put the disks in a usable order

In any valid stack, heights strictly increase from top to bottom. So if we **sort by height**, every valid stack appears as a subsequence of the sorted list (read from top to bottom). For each disk, we then only need to consider disks **earlier** in the sorted order as possible disks directly above it.

## Step 3: The DP

`H[i]` = the tallest stack that has disk `i` at the **bottom**.

```
H[i] = height[i] + max over j < i where disk j fits on disk i of H[j]      (or just height[i])
answer = max over i of H[i]
```

Store `prev[i]` (the disk placed directly on top of `i`) to reconstruct the stack.

## Step 4: The code

<!-- CODE:START -->

Full source: [`disk_stacking.dart`](disk_stacking.dart) (run it with `dart run`).

```dart
// Disk Stacking: disks [width, depth, height]. A disk can sit on another only if it is strictly
// smaller in all three dimensions. Maximize total height. Returns the stack from top to bottom
// (smallest first). Sort by height, then LIS-style DP. O(n^2) time, O(n) space.

List<List<int>> diskStacking(List<List<int>> disks) {
  if (disks.isEmpty) return [];
  final d = [...disks]..sort((a, b) => a[2].compareTo(b[2]));
  final heights = [for (final x in d) x[2]];
  final prev = List<int?>.filled(d.length, null);
  var bestIdx = 0;
  bool fitsOn(List<int> top, List<int> bottom) => top[0] < bottom[0] && top[1] < bottom[1] && top[2] < bottom[2];

  for (var i = 1; i < d.length; i++) {
    for (var j = 0; j < i; j++) {
      if (fitsOn(d[j], d[i]) && heights[j] + d[i][2] > heights[i]) {
        heights[i] = heights[j] + d[i][2];
        prev[i] = j;
      }
    }
    if (heights[i] > heights[bestIdx]) bestIdx = i;
  }
  final stack = <List<int>>[];
  for (int? i = bestIdx; i != null; i = prev[i]) {
    stack.add(d[i]);
  }
  return stack.reversed.toList();
}
```

<!-- CODE:END -->

### Walkthrough

- `d` is the list sorted by height.
- `heights[i]` starts as the disk's own height.
- `fitsOn(top, bottom)` checks all three dimensions strictly.
- The double loop applies the recurrence and records `prev`.
- Reconstruction walks from the best bottom disk upward through `prev`; `.reversed` gives top-to-bottom order.

## Step 5: Dry run

Sorted by height: `[1,3,1], [2,1,2], [3,2,3], [2,3,4], [4,4,5], [2,2,8]` (indices 0..5).

| i | disk | fits on it (from earlier) | H[i] | prev |
|---|---|---|---|---|
| 0 | [1,3,1] | | 1 | |
| 1 | [2,1,2] | none ([1,3,1] has depth 3 > 1) | 2 | |
| 2 | [3,2,3] | [2,1,2] (H 2) | 5 | 1 |
| 3 | [2,3,4] | none fits strictly in all dims | 4 | |
| 4 | [4,4,5] | [1,3,1] (1), [2,1,2] (2), [3,2,3] (5) | **10** | 2 |
| 5 | [2,2,8] | none: [1,3,1] fails on depth (3 > 2), [2,1,2] on width (2 = 2), the rest are wider | 8 | |

Best bottom: disk 4 with height 10. Walk up: 4 -> 2 -> 1. Top to bottom: `[2,1,2], [3,2,3], [4,4,5]`.

## Complexity

- **Time: O(n^2)** (plus O(n log n) for sorting).
- **Space: O(n)**.

## Common mistakes

- Non-strict comparisons.
- Forgetting to sort (then an earlier disk in the input might need to go below a later one).
- Returning the stack bottom-to-top when top-to-bottom is required.

## Follow-ups

1. **Box stacking with rotations:** generate all 3 orientations of each box, then the same DP.
2. **Russian Doll Envelopes (LeetCode #354):** 2D version; sort by width ascending and height **descending**, then LIS on heights in O(n log n).
3. **Maximum Height by Stacking Cuboids (#1691):** rotations allowed; sort each cuboid's dimensions first.

## What to remember

Sort by one dimension so that valid chains become subsequences, then run the "best chain ending at i" DP with predecessor pointers.
