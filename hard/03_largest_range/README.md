# Largest Range

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Hash set, expand only from run starts

## Problem
Given an array of integers, return `[first, last]` of the largest range of consecutive integers that all appear in the array. The numbers need not be adjacent or sorted in the input. Assume a unique largest range.

```
[1, 11, 3, 0, 15, 5, 2, 4, 10, 7, 12, 6]  ->  [0, 7]
```

## Building up the logic
1. Sorting then scanning for consecutive runs: O(n log n). Correct and a good first answer.
2. For O(n): put everything in a hash set so "is `x + 1` present?" is O(1).
3. Naively expanding from every number repeats work (the run 0..7 would be walked from 0, 1, 2, ...), making it O(n^2).
4. **Key trick:** only expand from numbers that **start** a run, i.e. whose predecessor `x - 1` is absent. Each run is then walked exactly once, so the total work is O(n).
5. (AlgoExpert's reference variant marks visited numbers in a map while expanding in both directions; same complexity.)

## Complexity
- Time: O(n): each number is visited a constant number of times across all expansions.
- Space: O(n).

## Interview notes
- LeetCode #128 (Longest Consecutive Sequence), one of the most common FAANG array questions. The "only start from run beginnings" argument is what the interviewer wants to hear, together with why it makes the nested loop linear overall.
