# Disk Stacking

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Sort + LIS-style DP over a partial order

## Problem
Each disk has `[width, depth, height]`. You may stack disks (without rotating them); a disk can go on top of another only if it is **strictly** smaller in width, depth, and height. Build the tallest possible stack and return its disks ordered from top to bottom (smallest first). Assume a unique answer.

## Building up the logic
1. "Each item must be strictly smaller than the one below in every dimension" is a chain in a partial order, like increasing subsequences in multiple dimensions.
2. **Sort by one dimension** (height here). Any valid stack, read from top to bottom, appears in this sorted order, so each disk only needs to consider disks earlier in the sorted list as possible disks above it.
3. **Subproblem:** `H[i]` = max stack height with disk `i` at the **bottom**.
4. **Recurrence:** `H[i] = h_i + max(H[j])` over `j < i` where disk `j` fits on disk `i` in all dimensions.
5. Track `prev[i]` for reconstruction; the answer ends at `argmax H`.

## Complexity
- Time: O(n^2) (plus O(n log n) for sorting).
- Space: O(n).

## Interview notes
- Same template as Box Stacking (with rotations, generate all 3 orientations first) and Russian Doll Envelopes (LeetCode #354: 2D, which has an O(n log n) trick: sort by width ascending and height **descending**, then LIS on heights).
