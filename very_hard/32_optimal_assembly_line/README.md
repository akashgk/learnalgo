# Optimal Assembly Line

**Difficulty:** Very Hard | **Category:** Searching | **Pattern:** Binary search on the answer + greedy check

## Problem
An assembly line has ordered steps with given durations. You must group the steps, in order, into at most `numStations` contiguous stations. A station's time is the sum of its steps, and the line runs at the speed of the slowest station. Return the minimum possible maximum station time.

```
steps = [15, 15, 30, 30, 45], stations = 3  ->  60
```
Why 60: 45 cannot share a station with a 30 (75), so it sits alone. The remaining `[15, 15, 30, 30]` must fit in two stations, and both splits `[15, 15, 30] [30]` and `[15, 15] [30, 30]` peak at 60.

## Building up the logic
1. DP: `best[i][k]` = min max-time to put the first i steps into k stations: O(n^2 * k).
2. **Flip the question:** "given a time limit T, can the steps fit into at most k stations?" is easy: greedily fill each station until the next step would exceed T, then open a new one. Greedy is optimal for this check (packing as much as possible into each station never hurts later stations).
3. Feasibility is **monotonic** in T: if T works, any larger T works. So binary search T between `max(step)` (every station must hold its largest step) and `sum(steps)` (one station).
4. The smallest feasible T is the answer.

## Complexity
- Time: O(n log S), S = sum of durations.
- Space: O(1).

## Interview notes
- Identical to LeetCode #410 (Split Array Largest Sum) and #1011 (Capacity To Ship Packages Within D Days). "Binary search on the answer" is a pattern FAANG interviewers love because it combines a monotonic predicate with a greedy check.
