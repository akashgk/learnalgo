# Water Area

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Prefix/suffix maxima -> two pointers

## The problem

An array of non-negative integers represents pillars of width 1 and the given heights. After it rains, how many units of water are trapped between the pillars?

```
[0, 8, 0, 0, 5, 0, 0, 10, 0, 0, 1, 1, 0, 3]  ->  48

        |
        |
  |     |
  |     |
  |     |
  |  |  |
  |  |  |
  |  |  |     |
  |  |  |  || |
```

## Step 1: Think about one index at a time

Trying to identify "pools" and compute their volumes is messy. Instead ask: **how much water sits directly above index i?**

Water above `i` is held by the tallest pillar to its left and the tallest pillar to its right. The water level is the **lower** of those two walls:

```
water[i] = max(0, min(maxLeft[i], maxRight[i]) - height[i])
```

(Using maxima that include `i` itself makes the `max(0, ...)` unnecessary.)

The answer is the sum over all indices. This local formula is the key insight.

## Step 2: Brute force

For each index, scan left and right for the maxima: **O(n^2)**.

## Step 3: Precompute the maxima (DP)

`maxLeft[i]` is a running maximum from the left; `maxRight[i]` from the right. Two passes to fill them, one pass to sum: **O(n) time, O(n) space**.

## Step 4: Two pointers: O(1) space

Put `lo` at the left end and `hi` at the right end, tracking `leftMax` and `rightMax` seen so far.

**Key argument:** if `height[lo] < height[hi]`, then there is a wall on the right that is at least `height[hi]`, which is taller than `height[lo]`. The true right maximum for index `lo` is therefore at least `height[hi] > height[lo]`, and the water at `lo` is limited by `leftMax` alone: `water = leftMax - height[lo]` (after updating `leftMax`). We can finalize `lo` and move it right, without knowing the exact right maximum.

Symmetrically, if `height[hi] <= height[lo]`, finalize `hi` using `rightMax` and move it left.

## Step 5: The code

<!-- CODE:START -->

Full source: [`water_area.dart`](water_area.dart) (run it with `dart run`).

```dart
// Water Area (trapping rain water). Two pointers moving inward from the lower wall.
// Water above i = min(maxLeft, maxRight) - height[i]. O(n) time, O(1) space.

int waterArea(List<int> heights) {
  var lo = 0, hi = heights.length - 1;
  var leftMax = 0, rightMax = 0, water = 0;
  while (lo < hi) {
    if (heights[lo] < heights[hi]) {
      // The right side has a wall at least this tall, so the left max is the binding limit.
      if (heights[lo] > leftMax) leftMax = heights[lo];
      water += leftMax - heights[lo];
      lo++;
    } else {
      if (heights[hi] > rightMax) rightMax = heights[hi];
      water += rightMax - heights[hi];
      hi--;
    }
  }
  return water;
}
```

<!-- CODE:END -->

### Walkthrough

- `lo` and `hi` move inward; `leftMax` / `rightMax` are the tallest pillars seen from each side.
- The branch processes the side with the **lower** pillar, as argued in Step 4.
- `water += leftMax - heights[lo]` is never negative because `leftMax` was just updated to include `heights[lo]`.

## Step 6: Per-index view of the example

| index | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| height | 0 | 8 | 0 | 0 | 5 | 0 | 0 | 10 | 0 | 0 | 1 | 1 | 0 | 3 |
| maxLeft | 0 | 8 | 8 | 8 | 8 | 8 | 8 | 10 | 10 | 10 | 10 | 10 | 10 | 10 |
| maxRight | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 3 | 3 | 3 | 3 | 3 | 3 |
| water | 0 | 0 | 8 | 8 | 3 | 8 | 8 | 0 | 3 | 3 | 2 | 2 | 3 | 0 |

Total: 8 + 8 + 3 + 8 + 8 + 3 + 3 + 2 + 2 + 3 = **48**. The two-pointer version computes the same per-index amounts in a different order.

## Complexity

| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Prefix and suffix maxima | O(n) | O(n) |
| Two pointers | O(n) | O(1) |
| Monotonic stack (fills layer by layer) | O(n) | O(n) |

## Common mistakes

- Using the taller wall instead of the lower one.
- In the two-pointer version, moving the pointer on the taller side (the argument only holds for the lower side).

## Follow-ups

1. **Trapping Rain Water (LeetCode #42):** identical; one of the most asked hard problems at Google and Amazon.
2. **Trapping Rain Water II (#407):** 2D height map; process cells from the boundary inward with a min-heap (a Dijkstra-like flood).
3. **Container With Most Water (#11):** a different problem (choose two walls, no pillars in between count) with a similar two-pointer argument.

## What to remember

Water above a cell = min(tallest on the left, tallest on the right) - height. Two pointers finalize the side whose limiting wall is already known.
