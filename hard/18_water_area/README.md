# Water Area

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Prefix/suffix maxima -> two pointers

## Problem
Non-negative integers represent pillar heights of width 1. Return the total units of water trapped between pillars after rain.

```
[0, 8, 0, 0, 5, 0, 0, 10, 0, 0, 1, 1, 0, 3]  ->  48
```

## Building up the logic
1. Think per index, not per "pool". Water above index `i` = `min(tallest to the left, tallest to the right) - height[i]`, if positive. This local formula is the whole insight.
2. Brute force: compute both maxima for each i by scanning: O(n^2).
3. **DP:** precompute `leftMax[i]` in one pass and `rightMax[i]` in another. O(n) time, O(n) space.
4. **Two pointers:** at any moment, if `height[lo] < height[hi]`, then the right side already contains a wall at least `height[hi] > height[lo]`, so the water at `lo` is limited by `leftMax` alone (the unknown true right max is at least `height[hi]`). Process `lo` and move it. Symmetric otherwise. O(1) space.
5. Monotonic stack is a third O(n) approach (fills water layer by layer between bars).

## Complexity
| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^2) | O(1) |
| Prefix/suffix max arrays | O(n) | O(n) |
| Two pointers | O(n) | O(1) |

## Interview notes
- LeetCode #42 (Trapping Rain Water), among the most frequently asked hard problems at Google/Amazon. Be able to justify why the two-pointer step is safe; that is where candidates get probed.
- 2D follow-up (#407, Trapping Rain Water II) uses a min-heap from the boundary inward (Dijkstra-like).
