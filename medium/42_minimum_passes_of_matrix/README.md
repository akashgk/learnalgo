# Minimum Passes Of Matrix

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Multi-source BFS (levels = time)

## Problem
An integer matrix is given. In one pass, every negative number that is 4-directionally adjacent to a positive number becomes positive. (Zero is neither and does not spread.) Changes made during a pass only affect the next pass. Return the minimum number of passes to make every negative number positive, or -1 if impossible.

## Building up the logic
1. Simulation: repeatedly scan the whole matrix and flip, using a copy so flips within a pass do not cascade. O((w*h)^2) in the worst case.
2. Only cells adjacent to **newly** positive cells can change in the next pass. So track the frontier instead of rescanning.
3. This is BFS with **all initial positives as sources at once** (multi-source BFS). Each BFS level is one pass.
4. Processing level by level (swap in a fresh queue per pass) keeps the "changes only count next pass" rule automatically.
5. Count negatives up front; if any remain when the BFS stops, return -1.

## Complexity
- Time: O(w * h): each cell enters the queue at most once.
- Space: O(w * h).

## Interview notes
- Identical to LeetCode #994 (Rotting Oranges) and #542 (01 Matrix). Multi-source BFS is a pattern Google loves: "distance to the nearest X" for all cells at once.
