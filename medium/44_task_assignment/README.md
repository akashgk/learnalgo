# Task Assignment

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Sort + pair smallest with largest

## Problem
There are `k` workers and `2k` tasks with given durations. Each worker gets exactly two tasks and works on them one after the other; workers run in parallel. Assign tasks to minimize the time until all tasks are done (the largest pair sum). Return the pairs as **original indices**.

## Building up the logic
1. The finishing time is the maximum pair sum. We want to minimize the maximum.
2. The longest task must be paired with something. Pairing it with the shortest task minimizes that pair's sum.
3. Remove both and repeat: second longest with second shortest, and so on.
4. **Exchange argument:** if the longest task `L` is paired with `x` and the shortest `S` with `y`, then `x >= S` and `y <= L`. Swapping to `(L, S)` and `(x, y)` gives `L + S <= L + x` and `x + y <= x + L`. The maximum never increases.
5. Implementation detail: you must return original indices, so sort an index array by duration instead of sorting the durations directly (handles duplicate durations without a map of lists).

## Complexity
- Time: O(n log n).
- Space: O(n).

## Interview notes
- LeetCode #1877 (Minimize Maximum Pair Sum in Array). Same pairing pattern as Tandem Bicycle (max case) and Boats to Save People (#881).
