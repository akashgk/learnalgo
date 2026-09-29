# Apartment Hunting

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Nearest-occurrence precomputation (two sweeps)

## Problem
A street is a list of blocks; each block says which buildings (gym, school, store, ...) it contains. Given the list of required buildings, choose the block for your apartment that **minimizes the farthest distance** you would walk to reach any required building (you walk to the nearest instance of each). Return the block index. Every requirement exists somewhere on the street.

## Building up the logic
1. Brute force: for each block, for each requirement, scan outward for the nearest instance. O(b^2 * r).
2. The expensive part is "nearest instance of requirement r from block i", recomputed many times. Precompute it for every (r, i) pair.
3. Nearest occurrence from the **left** is one sweep remembering the last index where the requirement was seen. Nearest from the **right** is the same sweep backward. Take the min of the two. This is the same "previous/next occurrence" trick as in many array problems.
4. For each block, the walking cost is the max over requirements; choose the block with the smallest max. This is a **minimax** objective, so read the problem carefully (sum would give a different answer).

## Complexity
- Time: O(b * r).
- Space: O(b * r).

## Interview notes
- Clarify the objective: minimize the maximum distance (this problem) vs minimize the total distance. The second one on a line, with a single occurrence per requirement, is solved by the median.
- LeetCode #821 (Shortest Distance to a Character) is the single-requirement building block.
