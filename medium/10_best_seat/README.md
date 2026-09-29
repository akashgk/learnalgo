# Best Seat

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Scan runs of free cells

## Problem
A row of seats is given as 0 (free) and 1 (taken); the first and last seats are always taken. Choose the free seat that gives you the most space, meaning its distance to the nearest taken seat is as large as possible. On ties choose the lowest index. Return -1 if every seat is taken.

```
[1, 0, 1, 0, 0, 0, 1]  ->  4
```

## Building up the logic
1. Brute force: for each free seat, scan left and right for the nearest taken seat. O(n^2).
2. Think in **runs of free seats** between two taken seats. Inside a run, the best seat is its middle.
3. A run of `k` free seats gives a best distance of `ceil(k / 2) = (k + 1) ~/ 2` from the middle seat to the nearer taken seat. For even `k` the two middles tie; `(left + right) ~/ 2` picks the lower one.
4. One pass finds every run: jump `left` to the next taken seat each time.
5. Compare by distance, not by run length. Runs of 3 and 4 both give distance 2, so the earlier (lower index) one wins.

## Complexity
- Time: O(n).
- Space: O(1).

## Clarification note
AlgoExpert's reference solution ranks runs by their length. That can pick a longer run whose middle seat is **not** farther from neighbors (for example a run of 4 over an earlier run of 3). This version ranks by actual distance, which matches the stated goal. In an interview, ask which definition is intended.

## Interview notes
- LeetCode #849 (Maximize Distance to Closest Person) is the version where ends may be free, which adds edge runs whose best seat is the far end, with distance `k` instead of `ceil(k/2)`.
