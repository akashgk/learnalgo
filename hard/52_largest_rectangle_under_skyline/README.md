# Largest Rectangle Under Skyline

**Difficulty:** Hard | **Category:** Stacks | **Pattern:** Monotonic stack (previous/next smaller element)

## Problem
Building heights (width 1 each) form a skyline. Return the area of the largest rectangle that fits entirely under the skyline.

```
[1, 3, 3, 2, 4, 1, 5, 3, 2]  ->  9
```
Where 9 comes from: height 1 across all 9 buildings. Close competitors: height 2 across indices 1..4 (area 8), height 3 across indices 1..2 (area 6), height 2 across indices 6..8 (area 6).

## Building up the logic
1. Every optimal rectangle's height equals some bar's height (otherwise you could raise it). So for each bar `i`, find the widest rectangle of height `h[i]`: extend left and right until a **lower** bar.
2. Brute force extension per bar: O(n^2).
3. "Nearest lower bar to the left and right" for every index = previous/next smaller element = **monotonic stack**.
4. Keep indices with increasing heights on a stack. When bar `i` is lower than the top, the top's rectangle is finished: its right limit is `i`, and its left limit is the new top after popping (the previous smaller bar). Width = `i - left - 1`.
5. A sentinel height 0 at the end flushes all remaining bars.

## Complexity
- Time: O(n): each index is pushed and popped once.
- Space: O(n).

## Interview notes
- LeetCode #84, a top-tier hard problem at Google and Amazon. It powers #85 (Maximal Rectangle in a binary matrix): treat each row as a histogram of consecutive 1s above it and apply this per row.
